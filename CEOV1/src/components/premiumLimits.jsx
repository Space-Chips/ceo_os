import { base44 } from '@/api/base44Client';
import { format, startOfDay, startOfWeek } from 'date-fns';

// Limites freemium
export const PREMIUM_LIMITS = {
  FOCUS_SESSIONS_PER_DAY: 1,
  FOCUS_MAX_DURATION_MINUTES: 30,
  CEO_SESSIONS_PER_WEEK: 1,
  CEO_MAX_DURATION_MINUTES: 60,
  MAX_ACTIVE_HABITS: 3,
  MAX_ACTIVE_TASKS: 5
};

// Vérifier si l'utilisateur peut démarrer une session Focus
export async function canStartFocusSession(isPremiumUser, duration) {
  if (isPremiumUser) return { allowed: true };

  const today = startOfDay(new Date());
  const user = await base44.auth.me();
  
  // Vérifier le nombre de sessions aujourd'hui
  const todaySessions = await base44.entities.FocusSession.filter({
    created_by: user.email
  });
  
  const sessionsToday = todaySessions.filter(s => {
    const sessionDate = startOfDay(new Date(s.start_time));
    return sessionDate.getTime() === today.getTime();
  });

  if (sessionsToday.length >= PREMIUM_LIMITS.FOCUS_SESSIONS_PER_DAY) {
    return { 
      allowed: false, 
      reason: 'focus_daily',
      limit: PREMIUM_LIMITS.FOCUS_SESSIONS_PER_DAY,
      current: sessionsToday.length
    };
  }

  // Vérifier la durée
  if (duration > PREMIUM_LIMITS.FOCUS_MAX_DURATION_MINUTES) {
    return { 
      allowed: false, 
      reason: 'focus_duration',
      limit: PREMIUM_LIMITS.FOCUS_MAX_DURATION_MINUTES,
      current: duration
    };
  }

  return { allowed: true };
}

// Vérifier si l'utilisateur peut démarrer une session CEO
export async function canStartCEOSession(isPremiumUser, duration) {
  if (isPremiumUser) return { allowed: true };

  const weekStart = startOfWeek(new Date(), { weekStartsOn: 1 });
  const user = await base44.auth.me();
  
  // Vérifier le nombre de sessions cette semaine
  const allSessions = await base44.entities.CEOModeSession.filter({
    created_by: user.email
  });
  
  const sessionsThisWeek = allSessions.filter(s => {
    const sessionWeekStart = startOfWeek(new Date(s.start_time), { weekStartsOn: 1 });
    return sessionWeekStart.getTime() === weekStart.getTime();
  });

  if (sessionsThisWeek.length >= PREMIUM_LIMITS.CEO_SESSIONS_PER_WEEK) {
    return { 
      allowed: false, 
      reason: 'ceo_weekly',
      limit: PREMIUM_LIMITS.CEO_SESSIONS_PER_WEEK,
      current: sessionsThisWeek.length
    };
  }

  // Vérifier la durée
  if (duration > PREMIUM_LIMITS.CEO_MAX_DURATION_MINUTES) {
    return { 
      allowed: false, 
      reason: 'ceo_duration',
      limit: PREMIUM_LIMITS.CEO_MAX_DURATION_MINUTES,
      current: duration
    };
  }

  return { allowed: true };
}

// Vérifier si l'utilisateur peut créer une nouvelle habitude
export async function canCreateHabit(isPremiumUser) {
  if (isPremiumUser) return { allowed: true };

  const user = await base44.auth.me();
  const activeHabits = await base44.entities.Habit.filter({
    created_by: user.email,
    archived: false
  });

  if (activeHabits.length >= PREMIUM_LIMITS.MAX_ACTIVE_HABITS) {
    return { 
      allowed: false, 
      reason: 'habits',
      limit: PREMIUM_LIMITS.MAX_ACTIVE_HABITS,
      current: activeHabits.length
    };
  }

  return { allowed: true };
}

// Vérifier si l'utilisateur peut créer une nouvelle tâche
export async function canCreateTask(isPremiumUser) {
  if (isPremiumUser) return { allowed: true };

  const user = await base44.auth.me();
  const activeTasks = await base44.entities.ParetoTask.filter({
    created_by: user.email,
    completed: false
  });

  if (activeTasks.length >= PREMIUM_LIMITS.MAX_ACTIVE_TASKS) {
    return { 
      allowed: false, 
      reason: 'tasks',
      limit: PREMIUM_LIMITS.MAX_ACTIVE_TASKS,
      current: activeTasks.length
    };
  }

  return { allowed: true };
}

// Vérifier l'accès aux rapports
export function canAccessReports(isPremiumUser) {
  if (isPremiumUser) return { allowed: true };
  
  return { 
    allowed: false, 
    reason: 'reports'
  };
}

// Vérifier l'accès aux fonctionnalités avancées du calendrier
export function canAccessAdvancedCalendar(isPremiumUser) {
  if (isPremiumUser) return { allowed: true };
  
  return { 
    allowed: false, 
    reason: 'calendar_advanced'
  };
}