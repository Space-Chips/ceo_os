import React, { useState, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { getHabitsForDate, getHabitCompletionsForDate, calculateWeeklyHabitScore } from '../components/businessLogic';
import { format, startOfWeek, addDays } from 'date-fns';
import { ArrowLeft, Plus, CheckCircle2, XCircle, Trash2, Award, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { motion, AnimatePresence } from 'framer-motion';
import ObjectiveModal from '../components/habits/ObjectiveModal';
import HabitModal from '../components/habits/HabitModal';
import { useLanguage } from '../components/LanguageProvider.jsx';
import { usePremium } from '../components/PremiumProvider';
import { canCreateHabit } from '../components/premiumLimits';
import PremiumGate from '../components/PremiumGate';

export default function Habits() {
  const { t } = useLanguage();
  const { isPremiumUser } = usePremium();
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('grid');
  const [direction, setDirection] = useState(0);
  const [showObjectiveModal, setShowObjectiveModal] = useState(false);
  const [showHabitModal, setShowHabitModal] = useState(false);
  const [touchStart, setTouchStart] = useState(null);
  const [touchEnd, setTouchEnd] = useState(null);
  const [premiumBlock, setPremiumBlock] = useState(null);
  const weekStart = startOfWeek(new Date(), { weekStartsOn: 1 });
  
  const { data: objectives } = useQuery({
    queryKey: ['objectives'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.Objective.filter({ created_by: user.email, archived: false });
    },
    initialData: []
  });

  const { data: habits } = useQuery({
    queryKey: ['allHabits'],
    queryFn: async () => {
      const user = await base44.auth.me();
      const habits = await base44.entities.Habit.filter({ created_by: user.email, archived: false });
      
      // Sort habits by frequency: daily first (7), then by number of days per week (descending)
      return habits.sort((a, b) => {
        const freqA = a.is_daily ? 7 : (a.specific_days?.length || 0);
        const freqB = b.is_daily ? 7 : (b.specific_days?.length || 0);
        return freqB - freqA; // Descending order
      });
    },
    initialData: []
  });

  const { data: allCompletions } = useQuery({
    queryKey: ['completions', format(weekStart, 'yyyy-MM-dd')],
    queryFn: async () => {
      const user = await base44.auth.me();
      const allCompletions = await base44.entities.HabitCompletion.filter({
        created_by: user.email
      });
      return allCompletions.filter(c => {
        const cDate = new Date(c.date);
        return cDate >= weekStart && cDate < addDays(weekStart, 7);
      });
    },
    initialData: [],
    refetchInterval: 2000 // Refetch every 2 seconds for live updates
  });

  const weeklyScore = React.useMemo(() => {
    console.log('\n╔════════════════════════════════════════════════════════╗');
    console.log('║ [WEEKLY SCORE CALCULATION] START                       ║');
    console.log('╚════════════════════════════════════════════════════════╝');
    
    if (!habits || habits.length === 0 || !allCompletions) {
      console.log('⚠ No habits or completions, returning null');
      return null;
    }

    let totalValidated = 0;
    let totalCompleted = 0;
    const today = new Date(new Date().setHours(0, 0, 0, 0));
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    console.log(`📅 Today: ${format(today, 'yyyy-MM-dd')}`);
    console.log(`📅 Yesterday: ${format(yesterday, 'yyyy-MM-dd')}`);
    console.log(`📅 Week start: ${format(weekStart, 'yyyy-MM-dd')}\n`);

    for (let i = 0; i < 7; i++) {
      const day = addDays(weekStart, i);
      const dayNum = day.getDay();
      const dayStr = format(day, 'yyyy-MM-dd');
      const isPast = day < today;
      const isYesterday = day.getTime() === yesterday.getTime();
      const isLocked = isPast && !isYesterday;

      console.log(`\n--- Day ${i + 1}: ${dayStr} (${['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][dayNum]}) ---`);
      console.log(`   isPast: ${isPast}, isYesterday: ${isYesterday}, isLocked: ${isLocked}`);

      habits.forEach(habit => {
        const isScheduled = habit.is_daily || (habit.specific_days && habit.specific_days.includes(dayNum));
        if (isScheduled) {
          const completion = allCompletions.find(c => 
            c.habit_id === habit.id && 
            format(new Date(c.date), 'yyyy-MM-dd') === dayStr
          );
          
          console.log(`   Habit "${habit.title}":`);
          console.log(`     - isScheduled: ${isScheduled}`);
          console.log(`     - completion: ${completion ? `state=${completion.state}` : 'NONE'}`);
          console.log(`     - isLocked: ${isLocked}`);
          
          // Seuls les jours LOCKED (passés sauf hier) comptent automatiquement
          const notValidatedAndLocked = isLocked && !completion;
          
          console.log(`     - notValidatedAndLocked: ${notValidatedAndLocked}`);
          
          // Compter les habitudes validées OU locked non validées
          if (completion?.state === 'completed' || completion?.state === 'missed' || notValidatedAndLocked) {
            totalValidated++;
            console.log(`     → COUNT in total_expected (totalValidated++)`);
            
            if (completion?.state === 'completed' || completion?.completed === true) {
              totalCompleted++;
              console.log(`     → COUNT in total_completed (totalCompleted++)`);
            } else {
              console.log(`     → NOT completed (missed or locked)`);
            }
          } else {
            console.log(`     → NOT counted (future, today, or yesterday)`);
          }
        }
      });
    }

    const successPercentage = totalValidated > 0 
      ? Math.round((totalCompleted / totalValidated) * 100)
      : 0;

    console.log(`\n═══ FINAL RESULT ═══`);
    console.log(`✓ total_expected: ${totalValidated}`);
    console.log(`✓ total_completed: ${totalCompleted}`);
    console.log(`✓ success_percentage: ${successPercentage}%`);
    console.log('╚════════════════════════════════════════════════════════╝\n');

    return {
      total_expected: totalValidated,
      total_completed: totalCompleted,
      success_percentage: successPercentage,
      threshold_percentage: 90,
      threshold_met: successPercentage >= 90
    };
  }, [habits, allCompletions, weekStart]);

  const { data: weeklyContract } = useQuery({
    queryKey: ['currentContract', format(weekStart, 'yyyy-MM-dd')],
    queryFn: async () => {
      const user = await base44.auth.me();
      const contracts = await base44.entities.WeeklyContract.filter({
        created_by: user.email,
        week_start_date: format(weekStart, 'yyyy-MM-dd')
      });
      return contracts[0];
    }
  });

  const createObjectiveMutation = useMutation({
    mutationFn: async (data) => {
      const user = await base44.auth.me();
      return await base44.entities.Objective.create({
        ...data,
        created_by: user.email
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['objectives']);
      setShowObjectiveModal(false);
    }
  });

  const createHabitMutation = useMutation({
    mutationFn: async (data) => {
      // Vérifier les limites premium
      const check = await canCreateHabit(isPremiumUser);
      if (!check.allowed) {
        setPremiumBlock(check);
        setShowHabitModal(false);
        throw new Error('Premium limit reached');
      }

      const user = await base44.auth.me();
      return await base44.entities.Habit.create({
        ...data,
        created_by: user.email
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['allHabits']);
      setShowHabitModal(false);
      setPremiumBlock(null);
    },
    onError: (error) => {
      if (error.message !== 'Premium limit reached') {
        console.error('Habit creation error:', error);
      }
    }
  });

  const deleteObjectiveMutation = useMutation({
    mutationFn: async (objectiveId) => {
      const objectiveHabits = habits.filter(h => h.objective_id === objectiveId);
      await Promise.all(objectiveHabits.map(h => base44.entities.Habit.delete(h.id)));
      await base44.entities.Objective.delete(objectiveId);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['objectives']);
      queryClient.invalidateQueries(['allHabits']);
    }
  });

  const deleteHabitMutation = useMutation({
    mutationFn: async (habitId) => {
      await base44.entities.Habit.delete(habitId);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['allHabits']);
    }
  });

  const [contractForm, setContractForm] = useState({
    reward_text: '',
    sanction_text: '',
    success_threshold_percentage: 90
  });

  React.useEffect(() => {
    if (weeklyContract) {
      setContractForm({
        reward_text: weeklyContract.reward_text || '',
        sanction_text: weeklyContract.sanction_text || '',
        success_threshold_percentage: weeklyContract.success_threshold_percentage || 90
      });
    }
  }, [weeklyContract]);

  const updateContractMutation = useMutation({
    mutationFn: async (data) => {
      const user = await base44.auth.me();
      if (weeklyContract) {
        return await base44.entities.WeeklyContract.update(weeklyContract.id, data);
      } else {
        return await base44.entities.WeeklyContract.create({
          ...data,
          week_start_date: format(weekStart, 'yyyy-MM-dd'),
          week_end_date: format(addDays(weekStart, 6), 'yyyy-MM-dd'),
          created_by: user.email
        });
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['currentContract']);
    }
  });

  const groupedHabits = {};
  habits?.forEach(habit => {
    const objId = habit.objective_id;
    if (!groupedHabits[objId]) {
      groupedHabits[objId] = [];
    }
    groupedHabits[objId].push(habit);
  });

  const getDayAbbrev = (dayIndex) => ['M', 'T', 'W', 'T', 'F', 'S', 'S'][dayIndex];

  const isOnTrack = (weeklyScore?.success_percentage || 0) >= (weeklyScore?.threshold_percentage || 90);
  const isAtRisk = (weeklyScore?.success_percentage || 0) >= 70 && !isOnTrack;

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

    // Swipe vers la droite = accéder à goals (onglet à droite)
    // grid part vers la gauche, goals arrive de la droite
    if (isLeftSwipe && activeTab === 'grid') {
      setDirection(-1);
      setActiveTab('goals');
    }
    // Swipe vers la gauche = retour à grid (onglet à gauche)
    // goals part vers la droite, grid arrive de la gauche
    else if (isRightSwipe && activeTab === 'goals') {
      setDirection(1);
      setActiveTab('grid');
    }
  };

  return (
    <div 
      className="min-h-screen bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white p-4 sm:p-6 pt-16 sm:pt-20 pb-4 sm:pb-6 relative overflow-hidden"
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
    >
      {/* Noise texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.015]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulance type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      <div className="max-w-3xl mx-auto relative">
        <div className="flex items-center justify-between mb-4">
          <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 transition-colors duration-150 active:scale-95">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-xs font-medium">{t('home')}</span>
          </Link>

          <h1 className="text-xl font-black bg-gradient-to-r from-white via-zinc-100 to-zinc-300 bg-clip-text text-transparent tracking-tight">
            {t('habits')}
          </h1>
          
          <div className="w-20" />
        </div>

        {premiumBlock && (
          <div className="mb-6">
            <PremiumGate
              feature={premiumBlock.reason}
              limit={premiumBlock.limit}
              current={premiumBlock.current}
              compact={true}
            >
              {null}
            </PremiumGate>
          </div>
        )}

        <AnimatePresence mode="wait" custom={direction}>
        {activeTab === 'grid' && (
          <motion.div
            key="grid"
            custom={direction}
            initial={{ x: direction > 0 ? -300 : 300, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: direction > 0 ? 300 : -300, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            className="space-y-5">
            {/* Add Habit Button */}
            <div className="flex justify-end">
              <button
                onClick={() => setShowHabitModal(true)}
                className="px-3 py-1.5 rounded-lg bg-white text-black font-bold text-xs hover:bg-zinc-200 active:scale-95 transition-all duration-150 shadow-lg flex items-center gap-1.5"
              >
                <Plus className="w-3.5 h-3.5" />
                {t('habit')}
              </button>
            </div>

            {/* Habits Grid */}
            <div className="relative">
              <div className="absolute inset-0 bg-gradient-to-r from-zinc-700/10 to-zinc-600/10 rounded-xl blur-xl" />
              <div className="relative overflow-x-auto rounded-xl bg-zinc-900/60 border border-zinc-800/50 shadow-[0_12px_48px_rgba(0,0,0,0.5),inset_0_1px_0_rgba(255,255,255,0.02)]">
                <table className="w-full text-xs">
                  <thead>
                    <tr className="border-b border-zinc-800/50">
                      <th className="text-left py-2 px-3 text-zinc-600 font-black uppercase tracking-wider text-[10px]">{t('habit')}</th>
                      {[1,2,3,4,5,6,0].map(i => (
                        <th key={i} className="text-center py-2 px-1.5 text-zinc-600 font-black uppercase tracking-wider w-9 text-[9px]">
                          {getDayAbbrev(i === 0 ? 6 : i - 1)}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {habits?.map((habit, hIdx) => (
                      <tr key={habit.id} className="border-b border-zinc-900/50 hover:bg-zinc-900/30 transition-colors">
                        <td className="py-2 px-3 text-zinc-300 font-medium text-xs">{habit.title}</td>
                        {[1,2,3,4,5,6,0].map((dayNum, index) => {
                          // Calculer la date de ce jour
                          const day = addDays(weekStart, index);
                          const dayStr = format(day, 'yyyy-MM-dd');

                          // Vérifier si l'habitude est prévue ce jour
                          const isScheduled = habit.is_daily || (habit.specific_days && habit.specific_days.includes(dayNum));

                          // Si pas prévu, afficher un point
                          if (!isScheduled) {
                            return (
                              <td key={index} className="text-center py-3 px-2">
                                <span className="text-zinc-900">·</span>
                              </td>
                            );
                          }

                          // Récupérer la completion de ce jour
                          const completion = allCompletions?.find(c => 
                            c.habit_id === habit.id && 
                            format(new Date(c.date), 'yyyy-MM-dd') === dayStr
                          );

                          // Déterminer le statut temporel du jour
                          const today = new Date(new Date().setHours(0, 0, 0, 0));
                          const yesterday = new Date(today);
                          yesterday.setDate(yesterday.getDate() - 1);

                          const dayTimestamp = day.getTime();
                          const todayTimestamp = today.getTime();
                          const yesterdayTimestamp = yesterday.getTime();

                          const isToday = dayTimestamp === todayTimestamp;
                          const isYesterday = dayTimestamp === yesterdayTimestamp;
                          const isPastDay = dayTimestamp < todayTimestamp;

                          // Un jour est "locked" si c'est dans le passé ET ce n'est pas hier
                          const isLockedDay = isPastDay && !isYesterday;

                          // Déterminer l'état de cette cellule
                          const isCompleted = completion?.state === 'completed' || completion?.completed === true;
                          const isMissed = completion?.state === 'missed';

                          // Pour un jour LOCKED : TOUJOURS afficher l'état réel
                          if (isLockedDay) {
                            return (
                              <td key={index} className="text-center py-3 px-2">
                                {isCompleted ? (
                                  // Jour locked complété - Check vert
                                  <div className="inline-flex items-center justify-center">
                                    <div className="relative">
                                      <div className="absolute inset-0 bg-green-500/30 rounded-full blur-sm" />
                                      <CheckCircle2 className="relative w-5 h-5 text-green-400" />
                                    </div>
                                  </div>
                                ) : isMissed ? (
                                  // Jour locked manqué - X rouge
                                  <div className="inline-flex items-center justify-center">
                                    <div className="relative">
                                      <div className="absolute inset-0 bg-red-500/30 rounded-full blur-sm" />
                                      <X className="relative w-5 h-5 text-red-400" />
                                    </div>
                                  </div>
                                ) : (
                                  // Jour locked sans completion - Cercle rouge vide
                                  <div className="inline-flex items-center justify-center">
                                    <div className="relative">
                                      <div className="absolute inset-0 bg-red-500/30 rounded-full blur-sm" />
                                      <div className="relative w-5 h-5 rounded-full border-2 border-red-400 bg-red-950/50" />
                                    </div>
                                  </div>
                                )}
                              </td>
                            );
                          }

                          // Pour un jour NON-LOCKED (aujourd'hui, hier, futur)
                          // Vérifier si tous les jours précédents LOCKED sont complétés
                          let allPreviousLockedCompleted = true;
                          for (let i = 0; i < index; i++) {
                            const prevDay = addDays(weekStart, i);
                            const prevDayNum = [1,2,3,4,5,6,0][i];
                            const prevDayStr = format(prevDay, 'yyyy-MM-dd');
                            const prevIsScheduled = habit.is_daily || (habit.specific_days && habit.specific_days.includes(prevDayNum));

                            if (prevIsScheduled) {
                              const prevDayTimestamp = prevDay.getTime();
                              const prevIsYesterday = prevDayTimestamp === yesterdayTimestamp;
                              const prevIsPast = prevDayTimestamp < todayTimestamp;
                              const prevIsLocked = prevIsPast && !prevIsYesterday;

                              // Seuls les jours LOCKED doivent être vérifiés
                              if (prevIsLocked) {
                                const prevCompletion = allCompletions?.find(c => 
                                  c.habit_id === habit.id && 
                                  format(new Date(c.date), 'yyyy-MM-dd') === prevDayStr
                                );
                                const prevIsCompleted = prevCompletion?.state === 'completed' || prevCompletion?.completed === true;

                                if (!prevIsCompleted) {
                                  allPreviousLockedCompleted = false;
                                  break;
                                }
                              }
                            }
                          }

                          return (
                            <td key={index} className="text-center py-2 px-1.5 group relative">
                              {!allPreviousLockedCompleted ? (
                                // Jour bloqué car un jour locked précédent n'est pas complété
                                <div className="w-4 h-4 rounded-full border-2 border-zinc-900 inline-block opacity-20" />
                              ) : isCompleted ? (
                                // Jour complété
                                <div className="inline-flex items-center justify-center">
                                  <div className="relative">
                                    <div className="absolute inset-0 bg-green-500/30 rounded-full blur-sm" />
                                    <CheckCircle2 className="relative w-4 h-4 text-green-400" />
                                  </div>
                                </div>
                              ) : isMissed ? (
                                // Jour manqué
                                <div className="inline-flex items-center justify-center">
                                  <div className="relative">
                                    <div className="absolute inset-0 bg-red-500/30 rounded-full blur-sm" />
                                    <X className="relative w-4 h-4 text-red-400" />
                                  </div>
                                </div>
                              ) : (
                                // Jour non complété (hier, aujourd'hui, futur) - montrer l'habitude au hover
                                <div className="relative">
                                  <div className="w-4 h-4 rounded-full border-2 border-zinc-800 inline-block" />
                                  {/* Tooltip on hover showing habit name */}
                                  <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-zinc-900 border border-zinc-700 rounded-lg text-[9px] text-zinc-400 whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-10">
                                    {habit.title}
                                  </div>
                                </div>
                              )}
                            </td>
                          );
                        })}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Weekly Score */}
            <div className="relative">
              <div className={`absolute inset-0 rounded-xl blur-2xl transition-all duration-300 ${
                isOnTrack ? 'bg-gradient-to-r from-emerald-500/30 to-green-500/30 opacity-70' :
                isAtRisk ? 'bg-gradient-to-r from-yellow-500/25 to-orange-500/25 opacity-60' :
                'bg-gradient-to-r from-red-500/25 to-orange-500/25 opacity-55'
              }`} />
              <div className={`relative p-4 rounded-xl bg-gradient-to-br from-zinc-900/90 via-zinc-850/90 to-zinc-900/90 backdrop-blur-xl border-2 transition-all duration-300 shadow-[0_16px_64px_rgba(0,0,0,0.6),inset_0_1px_0_rgba(255,255,255,0.04)] ${
                isOnTrack ? 'border-emerald-600/50' :
                isAtRisk ? 'border-yellow-600/50' :
                'border-red-600/50'
              }`}>
                <div className="flex items-center justify-between mb-3">
                  <div>
                    <div className="text-[9px] text-zinc-600 font-semibold uppercase tracking-wider mb-0.5">
                        {format(weekStart, 'MMM d')} - {format(addDays(weekStart, 6), 'MMM d')}
                      </div>
                      <h2 className="text-base font-black text-zinc-200 tracking-tight">{t('weekScore')}</h2>
                  </div>
                  <div className="text-right">
                    <div className={`text-4xl font-black leading-none mb-0.5 ${
                      isOnTrack ? 'bg-gradient-to-br from-emerald-200 to-green-400 bg-clip-text text-transparent drop-shadow-[0_3px_10px_rgba(52,211,153,0.4)]' :
                      isAtRisk ? 'bg-gradient-to-br from-yellow-200 to-orange-400 bg-clip-text text-transparent drop-shadow-[0_3px_10px_rgba(251,191,36,0.4)]' :
                      'bg-gradient-to-br from-red-200 to-orange-400 bg-clip-text text-transparent drop-shadow-[0_3px_10px_rgba(248,113,113,0.4)]'
                    }`}>
                      {weeklyScore?.success_percentage || 0}
                    </div>
                    <div className="text-[9px] text-zinc-600 font-bold uppercase tracking-wider">{t('percent')}</div>
                  </div>
                </div>
                
                <div className="relative h-2.5 bg-black/40 rounded-full overflow-hidden shadow-[inset_0_2px_6px_rgba(0,0,0,0.6)] border border-zinc-900/50">
                  <div 
                    className={`h-full transition-all duration-700 shadow-[0_0_10px_currentColor] relative ${
                      isOnTrack ? 'bg-gradient-to-r from-emerald-500 to-green-400' :
                      isAtRisk ? 'bg-gradient-to-r from-yellow-500 to-orange-400' :
                      'bg-gradient-to-r from-red-500 to-orange-400'
                    }`}
                    style={{ width: `${weeklyScore?.success_percentage || 0}%` }}
                  >
                    <div className="absolute inset-0 bg-gradient-to-t from-white/0 to-white/20" />
                  </div>
                </div>

                <div className="flex justify-between mt-1.5">
                  <span className="text-[9px] text-zinc-600 font-medium">
                    {weeklyScore?.total_completed || 0} / {weeklyScore?.total_expected || 0}
                  </span>
                  <span className="text-[9px] text-zinc-600 font-medium">
                    {t('target')} {weeklyScore?.threshold_percentage || 90}%
                  </span>
                </div>
              </div>
            </div>

            {/* Swipe indicator */}
            <div className="text-center">
              <button
                onClick={() => setActiveTab('goals')}
                className="text-xs text-zinc-700 hover:text-zinc-500 font-medium transition-colors"
              >
                {t('swipeRightForGoals')}
              </button>
            </div>
          </motion.div>
        )}
        {activeTab === 'goals' && (
          <motion.div
            key="goals"
            custom={direction}
            initial={{ x: direction > 0 ? -300 : 300, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: direction > 0 ? 300 : -300, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            className="space-y-5">
            {/* Add Objective Button */}
            <div className="flex justify-end">
              <button
                onClick={() => setShowObjectiveModal(true)}
                className="px-3 py-1.5 rounded-lg bg-white text-black font-bold text-xs hover:bg-zinc-200 active:scale-95 transition-all duration-150 shadow-lg flex items-center gap-1.5"
              >
                <Plus className="w-3.5 h-3.5" />
                {t('goal')}
              </button>
            </div>

            {/* Objectives List */}
            <div className="space-y-2">
              {objectives?.map(obj => {
                const habitCount = groupedHabits[obj.id]?.length || 0;
                return (
                  <div key={obj.id} className="group relative">
                    <div className="relative p-3 rounded-xl bg-zinc-900/60 border border-zinc-800/50 hover:border-zinc-700/60 hover:bg-zinc-900/80 active:scale-[0.98] transition-all duration-150 shadow-[0_8px_24px_rgba(0,0,0,0.4)]">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          if (window.confirm('Delete this objective and all its habits?')) {
                            deleteObjectiveMutation.mutate(obj.id);
                          }
                        }}
                        className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity p-1 hover:bg-zinc-800/50 rounded-lg active:scale-95 duration-150"
                      >
                        <Trash2 className="w-3 h-3 text-red-500" />
                      </button>
                      <div className="flex items-center gap-2.5">
                        <span className="text-xl drop-shadow-lg">{obj.icon}</span>
                        <div className="flex-1">
                          <div className="font-bold text-white text-sm mb-0.5">{obj.title}</div>
                          <div className="text-[9px] text-zinc-600 font-semibold">{habitCount} habits</div>
                        </div>
                      </div>
                      
                      {/* Habits for this objective */}
                      {groupedHabits[obj.id] && groupedHabits[obj.id].length > 0 && (
                        <div className="mt-2 pt-2 border-t border-zinc-800/50 space-y-1">
                          {groupedHabits[obj.id].map(habit => (
                            <div key={habit.id} className="group/habit relative">
                              <div className="flex items-center justify-between p-1.5 rounded-lg bg-zinc-900/50 border border-zinc-800/50">
                                <span className="text-xs text-zinc-400 font-medium">{habit.title}</span>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    if (window.confirm('Delete this habit?')) {
                                      deleteHabitMutation.mutate(habit.id);
                                    }
                                  }}
                                  className="opacity-0 group-hover/habit:opacity-100 transition-opacity p-1 hover:bg-zinc-800/50 rounded active:scale-95"
                                >
                                  <Trash2 className="w-2.5 h-2.5 text-red-500" />
                                </button>
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Weekly Contract */}
            <div className="relative">
              <div className="absolute inset-0 bg-gradient-to-r from-purple-500/12 to-pink-500/12 rounded-xl blur-xl opacity-50" />
              <div className="relative p-4 rounded-xl bg-gradient-to-br from-zinc-900/85 via-zinc-850/85 to-zinc-900/85 backdrop-blur-xl border border-zinc-700/50 shadow-[0_12px_48px_rgba(0,0,0,0.5),inset_0_1px_0_rgba(255,255,255,0.03)]">
                <div className="flex items-center gap-2 mb-3">
                  <Award className="w-4 h-4 text-purple-400" />
                  <h2 className="text-sm font-black text-zinc-300 tracking-tight">WEEK CONTRACT</h2>
                </div>
                
                {!weeklyContract?.committed ? (
                  <div className="space-y-2">
                    <input
                      type="text"
                      value={contractForm.reward_text}
                      onChange={(e) => setContractForm(prev => ({ ...prev, reward_text: e.target.value }))}
                      placeholder={t('rewardIfSuccessful')}
                      className="w-full p-2.5 rounded-lg bg-black/40 border border-zinc-800/50 text-white text-xs placeholder:text-zinc-700 focus:border-green-500/50 focus:outline-none transition-all"
                    />

                    <input
                      type="text"
                      value={contractForm.sanction_text}
                      onChange={(e) => setContractForm(prev => ({ ...prev, sanction_text: e.target.value }))}
                      placeholder={t('sanctionIfFail')}
                      className="w-full p-2.5 rounded-lg bg-black/40 border border-zinc-800/50 text-white text-xs placeholder:text-zinc-700 focus:border-red-500/50 focus:outline-none transition-all"
                    />

                    <div>
                      <div className="flex items-center justify-between mb-1.5">
                        <span className="text-[9px] text-zinc-600 font-bold uppercase tracking-wider">{t('threshold')}</span>
                        <span className="text-lg font-black text-white">
                          {contractForm.success_threshold_percentage}%
                        </span>
                      </div>
                      <input
                        type="range"
                        min="50"
                        max="100"
                        step="5"
                        value={contractForm.success_threshold_percentage}
                        onChange={(e) => setContractForm(prev => ({ ...prev, success_threshold_percentage: parseInt(e.target.value) }))}
                        className="w-full h-1.5 bg-zinc-900 rounded-full appearance-none cursor-pointer [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3.5 [&::-webkit-slider-thumb]:h-3.5 [&::-webkit-slider-thumb]:bg-white [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:shadow-lg"
                      />
                    </div>

                    {contractForm.reward_text && contractForm.sanction_text && (
                      <Button
                        onClick={() => updateContractMutation.mutate({ 
                          ...contractForm,
                          committed: true 
                        })}
                        disabled={updateContractMutation.isPending}
                        className="w-full bg-white text-black hover:bg-zinc-200 h-9 text-xs font-bold rounded-lg active:scale-[0.98] transition-all duration-150"
                      >
                        {updateContractMutation.isPending ? t('committing') : t('commitContract')}
                      </Button>
                    )}
                  </div>
                ) : (
                  <div className="space-y-1.5">
                    <div className="p-3 rounded-lg bg-green-950/40 border-2 border-green-800/50 shadow-[inset_0_2px_6px_rgba(0,0,0,0.3)]">
                      <div className="text-[8px] text-green-500 font-black mb-0.5 uppercase tracking-wider">✓ {t('reward')}</div>
                      <div className="text-xs text-green-200 font-medium">{weeklyContract.reward_text}</div>
                    </div>

                    <div className="p-3 rounded-lg bg-red-950/40 border-2 border-red-800/50 shadow-[inset_0_2px_6px_rgba(0,0,0,0.3)]">
                      <div className="text-[8px] text-red-500 font-black mb-0.5 uppercase tracking-wider">⚠ {t('sanction')}</div>
                      <div className="text-xs text-red-200 font-medium">{weeklyContract.sanction_text}</div>
                    </div>

                    <div className="text-[9px] text-zinc-700 text-center font-medium pt-0.5">
                      {t('lockedUntilNextWeek')}
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Swipe indicator */}
            <div className="text-center">
              <button
                onClick={() => setActiveTab('grid')}
                className="text-xs text-zinc-700 hover:text-zinc-500 font-medium transition-colors"
              >
                {t('swipeLeftForHabits')}
              </button>
            </div>
          </motion.div>
        )}
        </AnimatePresence>
      </div>

      <ObjectiveModal
        open={showObjectiveModal}
        onClose={() => setShowObjectiveModal(false)}
        onSubmit={(data) => createObjectiveMutation.mutate(data)}
      />

      <HabitModal
        open={showHabitModal}
        onClose={() => setShowHabitModal(false)}
        onSubmit={(data) => createHabitMutation.mutate(data)}
        objectives={objectives}
      />
    </div>
  );
}