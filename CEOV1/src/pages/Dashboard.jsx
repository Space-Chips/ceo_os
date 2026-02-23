import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  getHabitsForDate, 
  getHabitCompletionsForDate,
  checkInHabit,
  ensureHabitsScheduled,
  transitionScheduledToPending
} from '../components/businessLogic';
import { base44 } from '@/api/base44Client';
import { format, subDays } from 'date-fns';
import { ArrowLeft, CheckCircle2, Circle, Check, Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useLanguage } from '../components/LanguageProvider.jsx';

export default function Dashboard() {
  const { t } = useLanguage();
  const queryClient = useQueryClient();
  const [yesterdayVisible, setYesterdayVisible] = useState(true);
  const [tempYesterdayStates, setTempYesterdayStates] = useState({});
  const [todayMarkedHabits, setTodayMarkedHabits] = useState({});

  // FIXED: Create dates once, not on every render
  const today = React.useMemo(() => {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    return d;
  }, []);
  
  const yesterday = React.useMemo(() => subDays(today, 1), [today]);

  const [todayHabitsWithCompletions, setTodayHabitsWithCompletions] = React.useState([]);
  const [pendingYesterdayHabits, setPendingYesterdayHabits] = React.useState([]);
  const [isLoading, setIsLoading] = React.useState(true);

  React.useEffect(() => {
    let mounted = true;
    
    const fetchData = async () => {
      try {
        setIsLoading(true);
        const user = await base44.auth.me();
        
        // Run all operations in parallel for faster loading
        const [
          _,
          __,
          allHabits,
          todayHabits,
          todayCompletions,
          yesterdayCompletions
        ] = await Promise.all([
          ensureHabitsScheduled(yesterday),
          transitionScheduledToPending(yesterday),
          base44.entities.Habit.filter({ created_by: user.email, archived: false }),
          getHabitsForDate(today),
          getHabitCompletionsForDate(today),
          getHabitCompletionsForDate(yesterday)
        ]);
        
        // Process today's data
        const scheduledCompletions = todayCompletions.filter(c => c.state === 'scheduled');
        const todayHabitsData = todayHabits.map(habit => {
          const completion = scheduledCompletions.find(c => c.habit_id === habit.id);
          return {
            ...habit,
            completionId: completion?.id,
            state: completion?.state || 'not_scheduled'
          };
        });
        
        // Process yesterday's pending validations
        const pendingCompletions = yesterdayCompletions.filter(c => c.state === 'pending_validation');
        const pendingWithHabits = pendingCompletions.map(completion => {
          const habit = allHabits.find(h => h.id === completion.habit_id);
          return {
            completionId: completion.id,
            habitId: completion.habit_id,
            habitTitle: habit?.title || 'Unknown Habit',
            completed: completion.completed || false,
            date: completion.date
          };
        });
        
        if (!mounted) return;
        
        setTodayHabitsWithCompletions(todayHabitsData);
        setPendingYesterdayHabits(pendingWithHabits);
        setIsLoading(false);
      } catch (error) {
        console.error('Dashboard fetch error:', error);
        if (mounted) setIsLoading(false);
      }
    };
    
    fetchData();
    
    return () => {
      mounted = false;
    };
  }, []);

  const { data: topTasks } = useQuery({
    queryKey: ['topTasks'],
    queryFn: async () => {
      const user = await base44.auth.me();
      const tasks = await base44.entities.ParetoTask.filter({ 
        created_by: user.email,
        completed: false
      });
      
      const importanceWeight = { crucial: 4, essential: 3, average: 2, low: 1 };
      const timeWeight = { 
        less_than_30min: 6, 
        '1_hour': 5, 
        '2_hours': 4, 
        half_day: 3, 
        '1_day': 2, 
        several_days: 1 
      };
      
      return tasks.sort((a, b) => {
        const scoreA = (importanceWeight[a.importance_level] || 0) * 10 + (timeWeight[a.time_duration] || 0);
        const scoreB = (importanceWeight[b.importance_level] || 0) * 10 + (timeWeight[b.time_duration] || 0);
        return scoreB - scoreA;
      }).slice(0, 3);
    },
    initialData: []
  });

  const { data: upcomingEvents } = useQuery({
    queryKey: ['upcomingEvents'],
    queryFn: async () => {
      const user = await base44.auth.me();
      const now = new Date();
      const todayStr = format(today, 'yyyy-MM-dd');
      
      const allEvents = await base44.entities.CalendarEvent.filter({ 
        created_by: user.email,
        event_date: todayStr
      });
      
      return allEvents.filter(event => {
        const [hours, minutes] = event.event_time.split(':').map(Number);
        const eventTime = new Date(today);
        eventTime.setHours(hours, minutes, 0, 0);
        return eventTime > now;
      }).sort((a, b) => a.event_time.localeCompare(b.event_time));
    },
    initialData: []
  });

  const toggleTodayMarked = (habitId) => {
    setTodayMarkedHabits(prev => ({
      ...prev,
      [habitId]: !prev[habitId]
    }));
  };

  const validateYesterdayMutation = useMutation({
    mutationFn: async () => {
      console.log('\n╔════════════════════════════════════════════════════════╗');
      console.log('║ [DASHBOARD] validateYesterdayMutation START            ║');
      console.log('╚════════════════════════════════════════════════════════╝');
      console.log('📋 Pending habits to validate:', pendingYesterdayHabits.length);
      console.log('📋 Temporary states:', tempYesterdayStates);
      
      if (!pendingYesterdayHabits || pendingYesterdayHabits.length === 0) {
        console.log('⚠ No pending habits, exiting');
        console.log('╚════════════════════════════════════════════════════════╝\n');
        return;
      }
      
      const promises = pendingYesterdayHabits.map(item => {
        const completedValue = tempYesterdayStates[item.habitId] || false;
        console.log(`→ Validating habit ${item.habitId} (${item.habitTitle}) as ${completedValue ? 'COMPLETED' : 'MISSED'}`);
        return checkInHabit(item.habitId, yesterday, completedValue);
      });
      
      await Promise.all(promises);
      console.log('✓ All habits validated');
      console.log('╚════════════════════════════════════════════════════════╝\n');
    },
    onSuccess: async () => {
      console.log('\n╔════════════════════════════════════════════════════════╗');
      console.log('║ [DASHBOARD] validateYesterdayMutation onSuccess        ║');
      console.log('╚════════════════════════════════════════════════════════╝');
      
      console.log('→ Invalidating queries...');
      queryClient.invalidateQueries(['weeklyScore']);
      queryClient.invalidateQueries(['weekData']);
      queryClient.invalidateQueries(['needsCheckIn']);
      queryClient.invalidateQueries(['completions']);
      queryClient.invalidateQueries(['allHabits']);
      console.log('✓ Queries invalidated');
      
      setYesterdayVisible(false);
      setTempYesterdayStates({});
      
      console.log('→ Reloading yesterday completions...');
      const yesterdayCompletions = await getHabitCompletionsForDate(yesterday);
      console.log(`✓ Found ${yesterdayCompletions.length} completions for yesterday`);
      
      const pendingCompletions = yesterdayCompletions.filter(c => c.state === 'pending_validation');
      console.log(`✓ ${pendingCompletions.length} still pending validation`);
      
      setPendingYesterdayHabits([]);
      console.log('✓ UI state cleared');
      console.log('╚════════════════════════════════════════════════════════╝\n');
    }
  });

  const toggleYesterdayHabit = (habitId) => {
    setTempYesterdayStates(prev => ({
      ...prev,
      [habitId]: !prev[habitId]
    }));
  };

  const completeTaskMutation = useMutation({
    mutationFn: async (taskId) => {
      await base44.entities.ParetoTask.update(taskId, {
        completed: true,
        completed_date: new Date().toISOString()
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['topTasks']);
      queryClient.invalidateQueries(['paretoTasks']);
    }
  });

  const needsYesterdayValidation = React.useMemo(() => {
    return pendingYesterdayHabits.length > 0;
  }, [pendingYesterdayHabits]);

  React.useEffect(() => {
    if (pendingYesterdayHabits && pendingYesterdayHabits.length > 0) {
      const initialStates = {};
      pendingYesterdayHabits.forEach(item => {
        initialStates[item.habitId] = item.completed;
      });
      setTempYesterdayStates(initialStates);
    }
  }, [pendingYesterdayHabits]);

  // Reset visual marks for today at midnight
  React.useEffect(() => {
    const todayKey = format(today, 'yyyy-MM-dd');
    const savedKey = localStorage.getItem('todayMarkedKey');
    if (savedKey !== todayKey) {
      setTodayMarkedHabits({});
      localStorage.setItem('todayMarkedKey', todayKey);
    }
  }, [today]);

  return (
    <div className="min-h-screen bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white p-6 pt-20 relative overflow-hidden">
      {/* Noise texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.015]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      <div className="max-w-2xl mx-auto">
        <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 mb-6 transition-colors duration-150 active:scale-95">
          <ArrowLeft className="w-4 h-4" />
          <span className="text-sm font-medium">{t('home')}</span>
        </Link>

        <div className="mb-6 relative">
          <h1 className="text-2xl font-black mb-2 bg-gradient-to-r from-white via-zinc-100 to-zinc-300 bg-clip-text text-transparent tracking-tight">
            {t('controlCenter')}
          </h1>
        </div>

        {/* ACTION ZONE - Layered visual hierarchy */}
        <div className="space-y-5 mb-12">
          {/* Yesterday Habits Validation Card - MANDATORY BLOCKING */}
          {yesterdayVisible && needsYesterdayValidation && (
            <div className="relative animate-in fade-in slide-in-from-top-4 duration-300">
              <div className="absolute inset-0 bg-gradient-to-r from-orange-500/40 to-red-500/40 rounded-[28px] blur-3xl opacity-80 animate-pulse" />
              <div className="relative p-5 rounded-[28px] bg-gradient-to-br from-zinc-900/95 via-zinc-850/95 to-zinc-900/95 backdrop-blur-xl border-2 border-orange-500/60 shadow-[0_24px_96px_rgba(249,115,22,0.5),0_0_0_1px_rgba(249,115,22,0.1),inset_0_1px_0_rgba(255,255,255,0.05)]">
                <div className="mb-4">
                  <h2 className="text-lg font-black text-orange-200 mb-1 tracking-tight">Habits from yesterday</h2>
                  <div className="text-[10px] text-orange-400/60 font-medium">Complete validation to continue</div>
                </div>
                <div className="space-y-1.5 mb-4">
                  {pendingYesterdayHabits.map(item => (
                    <button
                      key={item.completionId}
                      onClick={() => toggleYesterdayHabit(item.habitId)}
                      className="w-full flex items-center gap-3 p-3 rounded-xl bg-zinc-900/60 border border-zinc-800/60 hover:border-zinc-700/60 hover:bg-zinc-900/80 active:scale-[0.98] transition-all duration-150"
                    >
                      {tempYesterdayStates[item.habitId] ? (
                        <div className="relative">
                          <div className="absolute inset-0 bg-green-500/30 rounded-full blur-md" />
                          <CheckCircle2 className="relative w-5 h-5 text-green-400 flex-shrink-0" />
                        </div>
                      ) : (
                        <Circle className="w-5 h-5 text-zinc-600 flex-shrink-0" />
                      )}
                      <span className={`text-sm font-medium ${tempYesterdayStates[item.habitId] ? 'text-zinc-500 line-through' : 'text-white'}`}>
                        {item.habitTitle}
                      </span>
                    </button>
                  ))}
                </div>
                <Button
                  onClick={() => validateYesterdayMutation.mutate()}
                  disabled={validateYesterdayMutation.isPending}
                  className="w-full bg-gradient-to-r from-blue-500 to-blue-600 text-white hover:from-blue-600 hover:to-blue-700 h-11 text-sm font-bold rounded-xl shadow-[0_8px_24px_rgba(59,130,246,0.4)] hover:shadow-[0_12px_32px_rgba(59,130,246,0.5)] active:scale-[0.98] transition-all duration-150"
                >
                  <Check className="w-4 h-4 mr-2" />
                  {validateYesterdayMutation.isPending ? 'Confirming...' : 'Confirm'}
                </Button>
              </div>
            </div>
          )}

          {/* Today's Habits Status Card - AWARENESS ONLY */}
          <div className="relative animate-in fade-in zoom-in-95 duration-300">
            <div className="absolute inset-0 bg-gradient-to-r from-blue-500/20 to-purple-500/20 rounded-[28px] blur-2xl opacity-60" />
            <div className="relative p-5 rounded-[28px] bg-gradient-to-br from-zinc-900/95 via-zinc-850/95 to-zinc-900/95 backdrop-blur-xl border-2 border-zinc-700/50 shadow-[0_24px_96px_rgba(0,0,0,0.6),inset_0_1px_0_rgba(255,255,255,0.05)]">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-black text-zinc-200 tracking-tight">Habits for today</h2>
                <Link 
                  to={createPageUrl('Habits')}
                  className="p-2 hover:bg-zinc-800/50 rounded-lg transition-all duration-150 active:scale-95"
                >
                  <Plus className="w-4 h-4 text-zinc-400" />
                </Link>
              </div>
              <div className="space-y-1.5">
                {isLoading ? (
                  <div className="text-center py-12 text-zinc-600 text-sm font-medium">
                    {t('loading')}...
                  </div>
                ) : todayHabitsWithCompletions && todayHabitsWithCompletions.length > 0 ? (
                  todayHabitsWithCompletions.map((habit, idx) => {
                    const isMarked = todayMarkedHabits[habit.id];
                    
                    return (
                      <button
                        key={habit.id}
                        onClick={() => toggleTodayMarked(habit.id)}
                        className="w-full group relative"
                      >
                        <div className={`relative flex items-center gap-3 p-3 rounded-xl border transition-all duration-150 ${
                          isMarked
                            ? 'bg-zinc-900/40 border-zinc-800/40' 
                            : 'bg-zinc-900/60 border-zinc-800/60 hover:border-zinc-700/60 hover:bg-zinc-900/80'
                        }`}>
                          <span className={`flex-1 text-left transition-all duration-200 ${
                            isMarked 
                              ? 'text-zinc-600 text-xs font-normal' 
                              : 'text-white text-sm font-medium'
                          }`}>
                            {habit.title}
                          </span>
                          <div className={`w-6 h-6 rounded-lg flex items-center justify-center text-[9px] font-black transition-all ${
                            isMarked
                              ? 'bg-zinc-850/60 text-zinc-700'
                              : 'bg-zinc-800/60 text-zinc-600'
                          }`}>
                            {idx + 1}
                          </div>
                        </div>
                      </button>
                    );
                  })
                ) : (
                  <div className="text-center py-8 text-zinc-600 text-sm font-medium">
                    {t('noHabitsToday')}
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Upcoming Events - SECONDARY FOCUS */}
          {upcomingEvents && upcomingEvents.length > 0 && (
            <div className="relative animate-in fade-in zoom-in-95 duration-300 delay-75">
              <div className="absolute inset-0 bg-gradient-to-r from-purple-500/20 to-pink-500/20 rounded-[24px] blur-2xl opacity-60" />
              <div className="relative p-4 rounded-[24px] bg-gradient-to-br from-zinc-900/90 via-zinc-850/90 to-zinc-900/90 backdrop-blur-xl border border-zinc-700/50 shadow-[0_16px_64px_rgba(0,0,0,0.5),inset_0_1px_0_rgba(255,255,255,0.03)]">
                <div className="flex items-center justify-between mb-3">
                  <h2 className="text-base font-black text-zinc-300 tracking-tight">{t('schedule')}</h2>
                  <Link 
                    to={createPageUrl('Calendar')}
                    className="text-[10px] text-zinc-500 hover:text-zinc-300 font-semibold uppercase tracking-wider transition-colors duration-150"
                  >
                    {t('viewAll')} →
                  </Link>
                </div>
                <div className="space-y-1.5">
                  {upcomingEvents.slice(0, 3).map((event) => (
                    <div
                      key={event.id}
                      className="flex items-center gap-3 p-3 rounded-xl bg-zinc-900/50 border border-zinc-800/50"
                    >
                      <div className="w-7 h-7 rounded-lg bg-zinc-800/60 flex items-center justify-center shadow-[inset_0_2px_4px_rgba(0,0,0,0.4)]">
                        <span className="text-[10px] font-bold text-zinc-400">{event.event_time.substring(0, 5)}</span>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="text-sm font-semibold text-white truncate">{event.title}</div>
                        {event.description && (
                          <div className="text-[10px] text-zinc-500 truncate">{event.description}</div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Priority Tasks - SECONDARY FOCUS */}
          {topTasks && topTasks.length > 0 && (
            <div className="relative animate-in fade-in zoom-in-95 duration-300 delay-75">
              <div className="absolute inset-0 bg-gradient-to-r from-indigo-500/20 to-purple-500/20 rounded-[24px] blur-2xl opacity-60" />
              <div className="relative p-4 rounded-[24px] bg-gradient-to-br from-zinc-900/90 via-zinc-850/90 to-zinc-900/90 backdrop-blur-xl border border-zinc-700/50 shadow-[0_16px_64px_rgba(0,0,0,0.5),inset_0_1px_0_rgba(255,255,255,0.03)]">
                <div className="flex items-center justify-between mb-3">
                  <h2 className="text-base font-black text-zinc-300 tracking-tight">{t('priorities')}</h2>
                  <Link 
                    to={createPageUrl('Pareto')}
                    className="text-[10px] text-zinc-500 hover:text-zinc-300 font-semibold uppercase tracking-wider transition-colors duration-150"
                  >
                    {t('viewAll')} →
                  </Link>
                </div>
                <div className="space-y-1.5">
                  {topTasks.map((task, index) => {
                    const importanceBadge = {
                      crucial: { text: 'CRITICAL', color: 'text-red-300 bg-red-950/60 border-red-800/60' },
                      essential: { text: 'HIGH', color: 'text-yellow-300 bg-yellow-950/60 border-yellow-800/60' },
                      average: { text: 'MEDIUM', color: 'text-blue-300 bg-blue-950/60 border-blue-800/60' }
                    };

                    const badge = importanceBadge[task.importance_level] || importanceBadge.average;

                    return (
                      <button
                        key={task.id}
                        onClick={() => completeTaskMutation.mutate(task.id)}
                        className="w-full group text-left relative"
                      >
                        <div className="flex items-center gap-3 p-3 rounded-xl bg-zinc-900/50 border border-zinc-800/50 hover:border-green-500/50 hover:bg-zinc-900/70 active:scale-[0.98] transition-all duration-150">
                          <div className="w-6 h-6 rounded-lg bg-zinc-800/60 flex items-center justify-center text-xs font-black text-zinc-600 shadow-[inset_0_2px_4px_rgba(0,0,0,0.4)]">
                            {index + 1}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="text-sm font-semibold text-white mb-1 truncate">{task.title}</div>
                            <div className="flex items-center gap-2">
                              <span className={`text-[8px] px-1.5 py-0.5 rounded font-black border uppercase tracking-wider ${badge.color}`}>
                                {badge.text}
                              </span>
                              <span className="text-[9px] text-zinc-700 font-medium">
                                {task.time_duration.replace(/_/g, ' ')}
                              </span>
                            </div>
                          </div>
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}