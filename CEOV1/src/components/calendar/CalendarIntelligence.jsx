import { startOfDay, endOfDay, isSameDay, parseISO, differenceInMinutes } from 'date-fns';

// Détecte si une journée est surchargée
export function detectOverloadedDay(events, date) {
  const dayEvents = events.filter(e => isSameDay(new Date(e.event_date), date));
  
  if (dayEvents.length === 0) return { overloaded: false };
  
  // Calculer le temps total d'événements
  const totalMinutes = dayEvents.reduce((sum, e) => sum + (e.duration_minutes || 60), 0);
  
  // Vérifier les enchaînements sans pause
  const sortedEvents = [...dayEvents].sort((a, b) => {
    const timeA = a.event_time || '00:00';
    const timeB = b.event_time || '00:00';
    return timeA.localeCompare(timeB);
  });
  
  let hasNoBreaks = false;
  for (let i = 0; i < sortedEvents.length - 1; i++) {
    const current = sortedEvents[i];
    const next = sortedEvents[i + 1];
    
    const [currentHour, currentMin] = (current.event_time || '00:00').split(':').map(Number);
    const [nextHour, nextMin] = (next.event_time || '00:00').split(':').map(Number);
    
    const currentEndMinutes = currentHour * 60 + currentMin + (current.duration_minutes || 60);
    const nextStartMinutes = nextHour * 60 + nextMin;
    
    if (nextStartMinutes - currentEndMinutes < 15) {
      hasNoBreaks = true;
      break;
    }
  }
  
  return {
    overloaded: totalMinutes > 480 || hasNoBreaks || dayEvents.length > 6,
    reason: totalMinutes > 480 ? 'too_many_hours' : hasNoBreaks ? 'no_breaks' : 'too_many_events',
    totalMinutes,
    eventCount: dayEvents.length
  };
}

// Suggère du temps de focus si la journée est peu remplie
export function suggestFocusTime(events, date) {
  const dayEvents = events.filter(e => isSameDay(new Date(e.event_date), date));
  
  if (dayEvents.length === 0) {
    return {
      suggest: true,
      reason: 'no_events',
      recommendedDuration: 120
    };
  }
  
  const totalMinutes = dayEvents.reduce((sum, e) => sum + (e.duration_minutes || 60), 0);
  
  if (totalMinutes < 180) {
    return {
      suggest: true,
      reason: 'light_schedule',
      recommendedDuration: 90
    };
  }
  
  return { suggest: false };
}

// Calcule le temps réellement disponible dans une journée
export function calculateRealFreeTime(events, date) {
  const dayEvents = events.filter(e => isSameDay(new Date(e.event_date), date));
  
  // Temps total dans une journée (en minutes)
  const totalDayMinutes = 24 * 60; // 1440 minutes
  
  // Temps de sommeil estimé (8 heures)
  const sleepMinutes = 8 * 60; // 480 minutes
  
  // Temps d'événements
  const eventMinutes = dayEvents.reduce((sum, e) => sum + (e.duration_minutes || 60), 0);
  
  // Temps réellement disponible
  const freeTime = totalDayMinutes - sleepMinutes - eventMinutes;
  
  return {
    freeTimeMinutes: freeTime,
    freeTimeHours: Math.floor(freeTime / 60),
    freeTimeRemainingMinutes: freeTime % 60,
    eventMinutes,
    sleepMinutes,
    percentageFree: Math.round((freeTime / (totalDayMinutes - sleepMinutes)) * 100)
  };
}

// Vérifie la cohérence entre habitudes et calendrier
export async function checkHabitCalendarCoherence(habits, events, date) {
  const dayEvents = events.filter(e => isSameDay(new Date(e.event_date), date));
  const totalEventMinutes = dayEvents.reduce((sum, e) => sum + (e.duration_minutes || 60), 0);
  
  const dayOfWeek = date.getDay();
  const habitsForDay = habits.filter(h => {
    if (h.is_daily) return true;
    if (h.specific_days && h.specific_days.includes(dayOfWeek)) return true;
    return false;
  });
  
  // Si plus de 6 heures d'événements et des habitudes prévues
  if (totalEventMinutes > 360 && habitsForDay.length > 0) {
    return {
      conflict: true,
      reason: 'overloaded_day_with_habits',
      habitCount: habitsForDay.length,
      eventMinutes: totalEventMinutes
    };
  }
  
  return { conflict: false };
}

// Priorise automatiquement les événements
export function prioritizeEvents(events) {
  const importantKeywords = ['meeting', 'deadline', 'presentation', 'interview', 'important', 'urgent', 'critical'];
  const secondaryKeywords = ['optional', 'maybe', 'tentative', 'coffee', 'lunch'];
  
  return events.map(event => {
    const text = `${event.title} ${event.description || ''}`.toLowerCase();
    
    let priority = 'normal';
    if (importantKeywords.some(kw => text.includes(kw))) {
      priority = 'important';
    } else if (secondaryKeywords.some(kw => text.includes(kw))) {
      priority = 'secondary';
    }
    
    return { ...event, priority };
  });
}

// Analyse hebdomadaire intelligente
export function analyzeWeeklyCalendar(events, startDate, endDate) {
  const weekEvents = events.filter(e => {
    const eventDate = new Date(e.event_date);
    return eventDate >= startDate && eventDate <= endDate;
  });
  
  const totalEventMinutes = weekEvents.reduce((sum, e) => sum + (e.duration_minutes || 60), 0);
  
  // Calculer temps important vs secondaire
  const prioritizedEvents = prioritizeEvents(weekEvents);
  const importantMinutes = prioritizedEvents
    .filter(e => e.priority === 'important')
    .reduce((sum, e) => sum + (e.duration_minutes || 60), 0);
  
  // Temps libre réel (7 jours * 16 heures éveillé)
  const totalWakingMinutes = 7 * 16 * 60;
  const freeMinutes = totalWakingMinutes - totalEventMinutes;
  
  return {
    totalEventHours: Math.round(totalEventMinutes / 60),
    importantEventHours: Math.round(importantMinutes / 60),
    freeTimeHours: Math.round(freeMinutes / 60),
    percentageImportant: totalEventMinutes > 0 ? Math.round((importantMinutes / totalEventMinutes) * 100) : 0,
    percentageFree: Math.round((freeMinutes / totalWakingMinutes) * 100),
    eventCount: weekEvents.length
  };
}

// Avertissement de conflit avec Focus/CEO
export function checkFocusCEOConflict(events, startTime, durationMinutes) {
  const startDate = new Date(startTime);
  const endDate = new Date(startDate.getTime() + durationMinutes * 60000);
  
  const conflictingEvents = events.filter(e => {
    const eventDate = new Date(e.event_date);
    if (!isSameDay(eventDate, startDate)) return false;
    
    const [hour, min] = (e.event_time || '00:00').split(':').map(Number);
    const eventStart = new Date(eventDate);
    eventStart.setHours(hour, min, 0, 0);
    
    const eventEnd = new Date(eventStart.getTime() + (e.duration_minutes || 60) * 60000);
    
    // Vérifier le chevauchement
    return (startDate < eventEnd && endDate > eventStart);
  });
  
  const importantConflicts = prioritizeEvents(conflictingEvents).filter(e => e.priority === 'important');
  
  return {
    hasConflict: conflictingEvents.length > 0,
    conflicts: conflictingEvents,
    importantConflicts: importantConflicts,
    severity: importantConflicts.length > 0 ? 'high' : conflictingEvents.length > 0 ? 'medium' : 'none'
  };
}