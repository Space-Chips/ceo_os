import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { ArrowLeft } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import EventModal from '../components/calendar/EventModal';
import CalendarView from '../components/calendar/CalendarView';
import DayIntelligence from '../components/calendar/DayIntelligence';
import WeeklyAnalysis from '../components/calendar/WeeklyAnalysis';
import FocusCEOConflictWarning from '../components/calendar/FocusCEOConflictWarning';
import { useLanguage } from '../components/LanguageProvider';
import { 
  detectOverloadedDay, 
  suggestFocusTime, 
  calculateRealFreeTime,
  checkHabitCalendarCoherence,
  analyzeWeeklyCalendar,
  prioritizeEvents
} from '../components/calendar/CalendarIntelligence';
import { startOfWeek, endOfWeek } from 'date-fns';

export default function Calendar() {
  const { t } = useLanguage();
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const [showEventModal, setShowEventModal] = useState(false);
  const [prefilledEvent, setPrefilledEvent] = useState(null);
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [showConflictWarning, setShowConflictWarning] = useState(null);
  const [activeTab, setActiveTab] = useState('calendar');
  const [direction, setDirection] = useState(0);
  const [touchStart, setTouchStart] = useState(null);
  const [touchEnd, setTouchEnd] = useState(null);

  const { data: eventTypes = [] } = useQuery({
    queryKey: ['eventTypes'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.EventType.filter({ created_by: user.email });
    }
  });
  
  const { data: events } = useQuery({
    queryKey: ['allEvents'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.CalendarEvent.filter({ created_by: user.email }, '-event_date');
    },
    initialData: []
  });

  const { data: habits } = useQuery({
    queryKey: ['habits'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.Habit.filter({ created_by: user.email, archived: false });
    },
    initialData: []
  });

  const createEventMutation = useMutation({
    mutationFn: async (data) => {
      const user = await base44.auth.me();
      return await base44.entities.CalendarEvent.create({
        ...data,
        created_by: user.email
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['allEvents']);
      setShowEventModal(false);
    }
  });

  // Analyse intelligente pour la journée sélectionnée
  const dayIntelligence = React.useMemo(() => {
    const overload = detectOverloadedDay(events, selectedDate);
    const focusSuggestion = suggestFocusTime(events, selectedDate);
    const freeTime = calculateRealFreeTime(events, selectedDate);
    const habitConflict = checkHabitCalendarCoherence(habits, events, selectedDate);
    
    return { overload, focusSuggestion, freeTime, habitConflict };
  }, [events, habits, selectedDate]);

  // Analyse hebdomadaire
  const weekAnalysis = React.useMemo(() => {
    const weekStart = startOfWeek(selectedDate, { weekStartsOn: 1 });
    const weekEnd = endOfWeek(selectedDate, { weekStartsOn: 1 });
    return analyzeWeeklyCalendar(events, weekStart, weekEnd);
  }, [events, selectedDate]);

  const handleStartFocusFromSuggestion = () => {
    navigate(createPageUrl('FocusMode'));
  };

  const minSwipeDistance = 50;

  const handleTouchStart = (e) => {
    setTouchEnd(null);
    setTouchStart(e.targetTouches[0].clientX);
  };

  const handleTouchMove = (e) => {
    setTouchEnd(e.targetTouches[0].clientX);
  };

  const handleTouchEnd = () => {
    if (!touchStart || !touchEnd) return;
    const distance = touchStart - touchEnd;
    const isLeftSwipe = distance > minSwipeDistance;
    const isRightSwipe = distance < -minSwipeDistance;

    if (isLeftSwipe && activeTab === 'calendar') {
      setDirection(-1);
      setActiveTab('stats');
    } else if (isRightSwipe && activeTab === 'stats') {
      setDirection(1);
      setActiveTab('calendar');
    }
  };

  return (
    <div 
      className="min-h-screen bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white p-4 sm:p-6 pt-16 sm:pt-20 relative overflow-hidden"
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
    >
      {/* Noise texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.015]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      <div className="max-w-4xl mx-auto relative">
        <div className="flex items-center justify-between mb-6">
          <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 transition-colors duration-150 active:scale-95">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-sm font-medium">{t('home')}</span>
          </Link>
          
          <h1 className="text-2xl font-black bg-gradient-to-r from-white via-zinc-100 to-zinc-300 bg-clip-text text-transparent tracking-tight">
            {t('schedule')}
          </h1>
          
          <Link to={createPageUrl('EventTypes')} className="px-3 py-1.5 rounded-xl bg-zinc-900/60 border border-zinc-800/50 hover:border-zinc-700/60 text-xs text-zinc-300 hover:text-white font-bold transition-all active:scale-95">
            Types
          </Link>
        </div>

        <AnimatePresence mode="wait" custom={direction}>
          {activeTab === 'calendar' && (
            <motion.div
              key="calendar"
              custom={direction}
              initial={{ x: direction > 0 ? -300 : 300, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              exit={{ x: direction > 0 ? 300 : -300, opacity: 0 }}
              transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            >
              <CalendarView
                events={prioritizeEvents(events)}
                onNewEvent={() => {
                  setPrefilledEvent(null);
                  setShowEventModal(true);
                }}
                onTimeClick={(date, time) => {
                  setPrefilledEvent({ event_date: date, event_time: time });
                  setShowEventModal(true);
                }}
                onDateChange={setSelectedDate}
                eventTypes={eventTypes}
              />

              <button
                onClick={() => setActiveTab('stats')}
                className="mt-6 text-center text-xs text-zinc-600 hover:text-zinc-400 transition-colors w-full"
              >
                Swipe right for stats & insights →
              </button>
            </motion.div>
          )}

          {activeTab === 'stats' && (
            <motion.div
              key="stats"
              custom={direction}
              initial={{ x: direction > 0 ? -300 : 300, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              exit={{ x: direction > 0 ? 300 : -300, opacity: 0 }}
              transition={{ type: 'spring', stiffness: 300, damping: 30 }}
              className="space-y-6"
            >
              <DayIntelligence
                overloadInfo={dayIntelligence.overload}
                focusSuggestion={dayIntelligence.focusSuggestion}
                freeTime={dayIntelligence.freeTime}
                habitConflict={dayIntelligence.habitConflict}
                onStartFocus={handleStartFocusFromSuggestion}
              />

              <WeeklyAnalysis analysis={weekAnalysis} />

              <button
                onClick={() => setActiveTab('calendar')}
                className="mt-6 text-center text-xs text-zinc-600 hover:text-zinc-400 transition-colors w-full"
              >
                ← Swipe left for calendar view
              </button>
            </motion.div>
          )}
        </AnimatePresence>

        {showConflictWarning && (
          <FocusCEOConflictWarning
            conflict={showConflictWarning}
            onProceed={() => {
              setShowConflictWarning(null);
              navigate(createPageUrl('FocusMode'));
            }}
            onCancel={() => setShowConflictWarning(null)}
          />
        )}

        <EventModal
          open={showEventModal}
          onClose={() => {
            setShowEventModal(false);
            setPrefilledEvent(null);
          }}
          onSubmit={(data) => createEventMutation.mutate(data)}
          initialData={prefilledEvent}
          eventTypes={eventTypes}
        />
      </div>
    </div>
  );
}