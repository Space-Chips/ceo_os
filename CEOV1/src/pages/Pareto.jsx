import React, { useState, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { ArrowLeft, Plus, X, Trash2, Zap, Grid3x3, Check, CheckCircle2 } from 'lucide-react';
import { format } from 'date-fns';
import { motion, AnimatePresence } from 'framer-motion';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useLanguage } from '../components/LanguageProvider.jsx';
import { usePremium } from '../components/PremiumProvider';
import { canCreateTask } from '../components/premiumLimits';
import PremiumGate from '../components/PremiumGate';

export default function Pareto() {
  const { t } = useLanguage();
  const { isPremiumUser } = usePremium();
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('list');
  const [direction, setDirection] = useState(0);
  const [touchStart, setTouchStart] = useState(null);
  const [touchEnd, setTouchEnd] = useState(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [premiumBlock, setPremiumBlock] = useState(null);
  const [newTask, setNewTask] = useState({
    title: '',
    time_duration: '1_hour',
    importance_level: 'crucial'
  });
  
  const { data: tasks } = useQuery({
    queryKey: ['paretoTasks'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.ParetoTask.filter({ 
        created_by: user.email
      });
    },
    initialData: []
  });

  const createTaskMutation = useMutation({
    mutationFn: async (taskData) => {
      // Vérifier les limites premium
      const check = await canCreateTask(isPremiumUser);
      if (!check.allowed) {
        setPremiumBlock(check);
        setShowAddForm(false);
        throw new Error('Premium limit reached');
      }

      const user = await base44.auth.me();
      return await base44.entities.ParetoTask.create({
        ...taskData,
        created_by: user.email
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['paretoTasks']);
      setShowAddForm(false);
      setNewTask({ title: '', time_duration: '1_hour', importance_level: 'crucial' });
      setPremiumBlock(null);
    },
    onError: (error) => {
      if (error.message !== 'Premium limit reached') {
        console.error('Task creation error:', error);
      }
    }
  });

  const deleteTaskMutation = useMutation({
    mutationFn: async (taskId) => {
      await base44.entities.ParetoTask.delete(taskId);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['paretoTasks']);
    }
  });

  const completeTaskMutation = useMutation({
    mutationFn: async (taskId) => {
      await base44.entities.ParetoTask.update(taskId, {
        completed: true,
        completed_date: new Date().toISOString()
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['paretoTasks']);
    }
  });

  const uncompleteTaskMutation = useMutation({
    mutationFn: async (taskId) => {
      await base44.entities.ParetoTask.update(taskId, {
        completed: false,
        completed_date: null
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['paretoTasks']);
    }
  });

  const uncompletedTasks = tasks?.filter(t => !t.completed) || [];
  
  const prioritizedTasks = React.useMemo(() => {
    if (!uncompletedTasks) return [];
    
    const importanceWeight = { crucial: 4, essential: 3, average: 2, low: 1 };
    const timeWeight = { 
      less_than_30min: 6, 
      '1_hour': 5, 
      '2_hours': 4, 
      half_day: 3, 
      '1_day': 2, 
      several_days: 1 
    };
    
    return [...uncompletedTasks].sort((a, b) => {
      const scoreA = (importanceWeight[a.importance_level] || 0) * 10 + (timeWeight[a.time_duration] || 0);
      const scoreB = (importanceWeight[b.importance_level] || 0) * 10 + (timeWeight[b.time_duration] || 0);
      return scoreB - scoreA;
    });
  }, [uncompletedTasks]);

  const topThree = prioritizedTasks.slice(0, 5);
  const others = prioritizedTasks.slice(5);
  
  const recentTasks = tasks?.sort((a, b) => {
    return new Date(b.created_date) - new Date(a.created_date);
  }) || [];

  const handleSubmit = (e) => {
    e.preventDefault();
    if (newTask.title.trim()) {
      createTaskMutation.mutate(newTask);
    }
  };

  // Swipe handling
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

    // Swipe vers la droite = accéder à l'onglet à droite
    // L'onglet actuel part vers la gauche (direction = -1)
    // L'onglet suivant arrive de la droite
    if (isLeftSwipe && activeTab === 'list') {
      setDirection(-1);
      setActiveTab('matrix');
    } else if (isLeftSwipe && activeTab === 'matrix') {
      setDirection(-1);
      setActiveTab('history');
    }
    // Swipe vers la gauche = accéder à l'onglet à gauche
    // L'onglet actuel part vers la droite (direction = 1)
    // L'onglet précédent arrive de la gauche
    else if (isRightSwipe && activeTab === 'matrix') {
      setDirection(1);
      setActiveTab('list');
    } else if (isRightSwipe && activeTab === 'history') {
      setDirection(1);
      setActiveTab('matrix');
    }
  };

  // Categorize tasks for Pareto Matrix (based on QUICK TO DO + IMPORTANCE)
  const quickImportant = uncompletedTasks.filter(t => 
    (t.importance_level === 'crucial' || t.importance_level === 'essential') &&
    (t.time_duration === 'less_than_30min' || t.time_duration === '1_hour')
  );
  
  const slowImportant = uncompletedTasks.filter(t => 
    (t.importance_level === 'crucial' || t.importance_level === 'essential') &&
    (t.time_duration === '2_hours' || t.time_duration === 'half_day' || t.time_duration === '1_day' || t.time_duration === 'several_days')
  );
  
  const quickNotImportant = uncompletedTasks.filter(t => 
    (t.importance_level === 'average' || t.importance_level === 'low') &&
    (t.time_duration === 'less_than_30min' || t.time_duration === '1_hour')
  );
  
  const slowNotImportant = uncompletedTasks.filter(t => 
    (t.importance_level === 'average' || t.importance_level === 'low') &&
    (t.time_duration === '2_hours' || t.time_duration === 'half_day' || t.time_duration === '1_day' || t.time_duration === 'several_days')
  );

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

      <div className="max-w-2xl mx-auto relative">
        <div className="flex items-center justify-between mb-4">
          <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 transition-colors duration-150 active:scale-95">
            <ArrowLeft className="w-3.5 h-3.5" />
            <span className="text-xs font-medium">{t('home')}</span>
          </Link>

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

        {/* Tabs with swipe animation */}
        <AnimatePresence mode="wait" custom={direction}>
        {activeTab === 'list' && (
          <motion.div
            key="list"
            custom={direction}
            initial={{ x: direction > 0 ? -300 : 300, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: direction > 0 ? 300 : -300, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
          >
            <div className="mb-6">
              <h1 className="text-3xl font-black mb-1.5 bg-gradient-to-r from-white via-red-100 to-orange-100 bg-clip-text text-transparent tracking-tight">
                {t('todo')}
              </h1>
              <div className="text-[10px] text-zinc-700 font-semibold uppercase tracking-widest">{t('twentyEightyRule')}</div>
            </div>

            {/* Add Task Form */}
            {showAddForm && (
              <div className="mb-4 relative animate-in fade-in slide-in-from-top-4 duration-300">
                <div className="absolute inset-0 bg-gradient-to-br from-blue-500/20 to-purple-500/20 rounded-xl blur-2xl" />
                <form onSubmit={handleSubmit} className="relative p-4 rounded-xl bg-gradient-to-br from-zinc-900/95 via-zinc-850/95 to-zinc-900/95 backdrop-blur-xl border border-zinc-700/50 shadow-[0_16px_64px_rgba(0,0,0,0.6),inset_0_1px_0_rgba(255,255,255,0.03)]">
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="text-sm font-black tracking-tight">{t('newTask')}</h3>
                    <button
                      type="button"
                      onClick={() => setShowAddForm(false)}
                      className="p-1.5 hover:bg-zinc-800/50 rounded-lg transition-all duration-150 active:scale-95"
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  </div>

                  <div className="space-y-3">
                    <div>
                      <Input
                        value={newTask.title}
                        onChange={(e) => setNewTask({ ...newTask, title: e.target.value })}
                        placeholder={t('whatNeedsToBeDone')}
                        className="bg-zinc-900/80 border-zinc-700/50 h-9 text-sm placeholder:text-zinc-600 focus:border-white/30 transition-all"
                        autoFocus
                      />
                    </div>

                    <div className="grid grid-cols-2 gap-2">
                      <div>
                        <Select
                          value={newTask.importance_level}
                          onValueChange={(value) => setNewTask({ ...newTask, importance_level: value })}
                        >
                          <SelectTrigger className="bg-zinc-900/80 border-zinc-700/50 h-8 text-xs">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="crucial">🔴 {t('crucial')}</SelectItem>
                            <SelectItem value="essential">🟡 {t('essential')}</SelectItem>
                            <SelectItem value="average">🔵 {t('average')}</SelectItem>
                            <SelectItem value="low">⚪ {t('low')}</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>

                      <div>
                        <Select
                          value={newTask.time_duration}
                          onValueChange={(value) => setNewTask({ ...newTask, time_duration: value })}
                        >
                          <SelectTrigger className="bg-zinc-900/80 border-zinc-700/50 h-8 text-xs">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="less_than_30min">{t('lessThan30min')}</SelectItem>
                            <SelectItem value="1_hour">{t('oneHour')}</SelectItem>
                            <SelectItem value="2_hours">{t('twoHours')}</SelectItem>
                            <SelectItem value="half_day">{t('halfDay')}</SelectItem>
                            <SelectItem value="1_day">{t('oneDay')}</SelectItem>
                            <SelectItem value="several_days">{t('multiDay')}</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                    </div>

                    <Button 
                      type="submit" 
                      disabled={!newTask.title.trim() || createTaskMutation.isPending}
                      className="w-full bg-white text-black hover:bg-zinc-200 h-9 text-sm font-bold rounded-lg active:scale-[0.98] transition-all duration-150"
                    >
                      {createTaskMutation.isPending ? `${t('add')}...` : t('addTask')}
                    </Button>
                  </div>
                </form>
              </div>
            )}

            {/* TOP 5 PRIORITIES */}
            {topThree.length > 0 && (
              <div className="mb-4">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <div className="w-0.5 h-6 bg-white rounded-full shadow-[0_0_12px_rgba(255,255,255,0.5)]" />
                    <h2 className="text-xl font-black tracking-tight bg-gradient-to-r from-white to-zinc-300 bg-clip-text text-transparent">
                      {t('yourPriorities')}
                    </h2>
                  </div>
                  {!showAddForm && (
                    <Button 
                      data-pareto-add
                      onClick={() => setShowAddForm(true)}
                      size="sm"
                      className="bg-white text-black hover:bg-zinc-200 h-8 px-3 text-xs font-bold rounded-lg active:scale-95 transition-all duration-150"
                    >
                      <Plus className="w-3 h-3 mr-1" />
                      {t('add')}
                    </Button>
                  )}
                </div>
                
                <div className="space-y-2">
                  {topThree.map((task, index) => {
                    const sizeScale = index === 0 ? 1 : index === 1 ? 0.95 : index === 2 ? 0.9 : index === 3 ? 0.85 : 0.8;
                    const opacityScale = index === 0 ? 1 : index === 1 ? 0.95 : 0.9;

                    const importanceColors = {
                      crucial: { 
                        glow: 'from-red-500/40 to-orange-500/40', 
                        border: 'border-red-500/60', 
                        bg: 'from-red-950/60 to-orange-950/60',
                        badge: 'text-red-200 bg-red-900/70 border-red-700/70'
                      },
                      essential: { 
                        glow: 'from-yellow-500/30 to-amber-500/30', 
                        border: 'border-yellow-500/50', 
                        bg: 'from-yellow-950/50 to-amber-950/50',
                        badge: 'text-yellow-200 bg-yellow-900/70 border-yellow-700/70'
                      },
                      average: { 
                        glow: 'from-blue-500/25 to-cyan-500/25', 
                        border: 'border-blue-500/40', 
                        bg: 'from-blue-950/40 to-cyan-950/40',
                        badge: 'text-blue-200 bg-blue-900/70 border-blue-700/70'
                      }
                    };

                    const colors = importanceColors[task.importance_level] || importanceColors.average;

                    return (
                      <div key={task.id} className="relative group animate-in fade-in zoom-in-95 duration-300" style={{ animationDelay: `${index * 50}ms`, opacity: opacityScale }}>
                        <div className={`absolute inset-0 bg-gradient-to-r ${colors.glow} rounded-2xl blur-2xl opacity-70 group-hover:opacity-100 transition-opacity duration-300`} />
                        <div 
                          onClick={() => deleteTaskMutation.mutate(task.id)}
                          style={{ transform: `scale(${sizeScale})`, transformOrigin: 'top' }}
                          className={`relative flex items-start gap-3 p-4 rounded-2xl bg-gradient-to-br ${colors.bg} backdrop-blur-xl border-2 ${colors.border} cursor-pointer hover:border-opacity-80 active:scale-[0.97] transition-all duration-150 shadow-[0_20px_80px_rgba(0,0,0,0.7),inset_0_1px_0_rgba(255,255,255,0.05)]`}
                        >
                          <div className={`w-10 h-10 rounded-xl bg-gradient-to-br from-white/10 to-white/5 flex items-center justify-center font-black text-lg text-white/90 shadow-[inset_0_2px_8px_rgba(0,0,0,0.4)] border border-white/10`}>
                            {index + 1}
                          </div>
                          <div className="flex-1 min-w-0 pt-0.5">
                            <div className="text-base font-bold text-white mb-1.5 leading-tight">{task.title}</div>
                            <div className="flex items-center gap-1.5 flex-wrap">
                              <span className={`text-[9px] px-2 py-1 rounded-md border font-black uppercase tracking-wider ${colors.badge}`}>
                                {task.importance_level}
                              </span>
                              <span className="text-[10px] text-zinc-500 font-medium">
                                {task.time_duration?.replace(/_/g, ' ') || '1 hour'}
                              </span>
                            </div>
                          </div>
                          <div className="opacity-0 group-hover:opacity-100 transition-opacity duration-150 pt-0.5">
                            <div className="p-1.5 rounded-lg bg-red-500/20 border border-red-500/40">
                              <Trash2 className="w-3.5 h-3.5 text-red-400" />
                            </div>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* OTHER TASKS - Visually recessed */}
            {others.length > 0 && (
              <div className="relative">
                <div className="flex items-center gap-2 mb-3">
                  <div className="w-0.5 h-5 bg-zinc-800 rounded-full" />
                  <h2 className="text-xs font-bold text-zinc-600 tracking-tight uppercase">{t('otherTasks')}</h2>
                </div>
                
                <div className="space-y-1.5">
                  {others.map((task, index) => {
                    const importanceBadge = {
                      crucial: { text: 'CRITICAL', color: 'text-red-400/60 bg-red-950/40 border-red-900/40' },
                      essential: { text: 'HIGH', color: 'text-yellow-400/60 bg-yellow-950/40 border-yellow-900/40' },
                      average: { text: 'MED', color: 'text-blue-400/60 bg-blue-950/40 border-blue-900/40' },
                      low: { text: 'LOW', color: 'text-zinc-500 bg-zinc-900/40 border-zinc-800/40' }
                    };

                    const badge = importanceBadge[task.importance_level];

                    return (
                      <div key={task.id} className="group relative opacity-60 hover:opacity-100 transition-opacity duration-200">
                        <div 
                          onClick={() => deleteTaskMutation.mutate(task.id)}
                          className="relative flex items-center gap-2 p-2.5 rounded-lg bg-zinc-900/40 border border-zinc-800/40 hover:border-zinc-700/60 hover:bg-zinc-900/60 cursor-pointer active:scale-[0.98] transition-all duration-150"
                        >
                          <div className="w-6 h-6 rounded-md bg-zinc-850/60 flex items-center justify-center text-[10px] font-bold text-zinc-700 shadow-[inset_0_2px_4px_rgba(0,0,0,0.4)]">
                            {index + 4}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="text-xs font-medium text-zinc-400 mb-0.5 truncate">{task.title}</div>
                            <div className="flex items-center gap-1.5">
                              <span className={`text-[8px] px-1.5 py-0.5 rounded border font-bold uppercase tracking-wider ${badge.color}`}>
                                {badge.text}
                              </span>
                              <span className="text-[8px] text-zinc-700">
                                {task.time_duration.replace(/_/g, ' ')}
                              </span>
                            </div>
                          </div>
                          <div className="opacity-0 group-hover:opacity-100 transition-opacity">
                            <Trash2 className="w-3 h-3 text-zinc-600" />
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Empty state */}
            {prioritizedTasks.length === 0 && !showAddForm && (
              <div className="relative">
                <div className="absolute inset-0 bg-gradient-to-r from-zinc-700/10 to-zinc-600/10 rounded-xl blur-2xl" />
                <div className="relative text-center py-16 px-4 rounded-xl bg-zinc-900/50 border border-zinc-800/50">
                  <Zap className="w-12 h-12 mx-auto mb-4 text-zinc-700" />
                  <div className="text-base font-bold text-zinc-500 mb-1.5">{t('noPrioritiesSet')}</div>
                  <div className="text-xs text-zinc-700 mb-4">{t('focusOnWhatMatters')}</div>
                  <Button 
                    onClick={() => setShowAddForm(true)}
                    className="bg-white text-black hover:bg-zinc-200 h-10 px-4 text-xs font-bold rounded-lg active:scale-95 transition-all duration-150"
                  >
                    <Plus className="w-3.5 h-3.5 mr-1.5" />
                    {t('addFirstTask')}
                  </Button>
                </div>
              </div>
            )}

            {/* Add button for non-empty state */}
            {prioritizedTasks.length > 0 && !showAddForm && (
              <div className="flex justify-center mt-6">
                <button
                  onClick={() => setShowAddForm(true)}
                  className="px-4 py-2.5 rounded-lg bg-zinc-900/60 border border-zinc-800/60 hover:border-zinc-700/60 hover:bg-zinc-900/80 text-xs font-semibold text-zinc-400 hover:text-zinc-300 active:scale-95 transition-all duration-150"
                >
                  <Plus className="w-3.5 h-3.5 inline mr-1.5" />
                  {t('addTask')}
                </button>
              </div>
            )}

            <button
              onClick={() => setActiveTab('matrix')}
              className="mt-6 text-center text-[10px] text-zinc-600 hover:text-zinc-400 transition-colors w-full"
            >
              {t('swipeRightForMatrix')}
            </button>
          </motion.div>
        )}

        {activeTab === 'matrix' && (
          <motion.div
            key="matrix"
            custom={direction}
            initial={{ x: direction > 0 ? -300 : 300, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: direction > 0 ? 300 : -300, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            className="space-y-6">
            <div className="mb-4">
              <h1 className="text-2xl font-black mb-1.5 bg-gradient-to-r from-white via-zinc-100 to-zinc-300 bg-clip-text text-transparent tracking-tight">
                {t('paretoMatrix')}
              </h1>
              <div className="text-[10px] text-zinc-700 font-semibold uppercase tracking-widest">{t('impactVsTime')}</div>
            </div>

            {/* Matrix with visible axes */}
            <div className="relative">
              {/* Axis Lines */}
              <div className="absolute left-1/2 top-0 bottom-0 w-px bg-zinc-800/50" />
              <div className="absolute top-1/2 left-0 right-0 h-px bg-zinc-800/50" />

              <div className="grid grid-cols-2 gap-2">
                {/* Quadrant 1: Quick & Important (DO NOW) */}
                <div className="relative">
                  <div className="absolute inset-0 bg-gradient-to-br from-red-500/20 to-orange-500/20 rounded-xl blur-xl" />
                  <div className="relative p-3 rounded-xl bg-zinc-900/70 border border-red-700/40 min-h-[200px]">
                    <div className="mb-2">
                      <div className="text-[10px] font-black text-red-300 uppercase tracking-wider mb-0.5">{t('doNow')}</div>
                      <div className="text-[8px] text-red-400/60">{t('quickHighImpact')}</div>
                    </div>
                    <div className="space-y-1.5">
                      {quickImportant.map(task => (
                        <button
                          key={task.id}
                          onClick={() => deleteTaskMutation.mutate(task.id)}
                          className="w-full text-left p-2 rounded-lg bg-red-950/30 border border-red-900/30 hover:border-red-800/50 hover:bg-red-950/50 active:scale-[0.98] transition-all"
                        >
                          <div className="text-[10px] font-semibold text-red-200 truncate">{task.title}</div>
                        </button>
                      ))}
                      {quickImportant.length === 0 && (
                        <div className="text-center py-6 text-zinc-700 text-[10px]">{t('empty')}</div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Quadrant 2: Takes Time & Important (PLAN) */}
                <div className="relative">
                  <div className="absolute inset-0 bg-gradient-to-br from-blue-500/20 to-purple-500/20 rounded-xl blur-xl" />
                  <div className="relative p-3 rounded-xl bg-zinc-900/70 border border-blue-700/40 min-h-[200px]">
                    <div className="mb-2">
                      <div className="text-[10px] font-black text-blue-300 uppercase tracking-wider mb-0.5">{t('plan')}</div>
                      <div className="text-[8px] text-blue-400/60">{t('takesTimeHighImpact')}</div>
                    </div>
                    <div className="space-y-1.5">
                      {slowImportant.map(task => (
                        <button
                          key={task.id}
                          onClick={() => deleteTaskMutation.mutate(task.id)}
                          className="w-full text-left p-2 rounded-lg bg-blue-950/30 border border-blue-900/30 hover:border-blue-800/50 hover:bg-blue-950/50 active:scale-[0.98] transition-all"
                        >
                          <div className="text-[10px] font-semibold text-blue-200 truncate">{task.title}</div>
                        </button>
                      ))}
                      {slowImportant.length === 0 && (
                        <div className="text-center py-6 text-zinc-700 text-[10px]">{t('empty')}</div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Quadrant 3: Quick & Low Impact (DELEGATE) */}
                <div className="relative">
                  <div className="absolute inset-0 bg-gradient-to-br from-yellow-500/20 to-amber-500/20 rounded-xl blur-xl" />
                  <div className="relative p-3 rounded-xl bg-zinc-900/70 border border-yellow-700/40 min-h-[200px]">
                    <div className="mb-2">
                      <div className="text-[10px] font-black text-yellow-300 uppercase tracking-wider mb-0.5">IF TIME</div>
                      <div className="text-[8px] text-yellow-400/60">{t('quickLowImpact')}</div>
                    </div>
                    <div className="space-y-1.5">
                      {quickNotImportant.map(task => (
                        <button
                          key={task.id}
                          onClick={() => deleteTaskMutation.mutate(task.id)}
                          className="w-full text-left p-2 rounded-lg bg-yellow-950/30 border border-yellow-900/30 hover:border-yellow-800/50 hover:bg-yellow-950/50 active:scale-[0.98] transition-all"
                        >
                          <div className="text-[10px] font-semibold text-yellow-200 truncate">{task.title}</div>
                        </button>
                      ))}
                      {quickNotImportant.length === 0 && (
                        <div className="text-center py-6 text-zinc-700 text-[10px]">{t('empty')}</div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Quadrant 4: Takes Time & Low Impact (ELIMINATE) */}
                <div className="relative">
                  <div className="absolute inset-0 bg-gradient-to-br from-zinc-600/20 to-zinc-500/20 rounded-xl blur-xl" />
                  <div className="relative p-3 rounded-xl bg-zinc-900/70 border border-zinc-700/40 min-h-[200px]">
                    <div className="mb-2">
                      <div className="text-[10px] font-black text-zinc-400 uppercase tracking-wider mb-0.5">{t('eliminate')}</div>
                      <div className="text-[8px] text-zinc-500/60">{t('takesTimeLowImpact')}</div>
                    </div>
                    <div className="space-y-1.5">
                      {slowNotImportant.map(task => (
                        <button
                          key={task.id}
                          onClick={() => deleteTaskMutation.mutate(task.id)}
                          className="w-full text-left p-2 rounded-lg bg-zinc-900/30 border border-zinc-800/30 hover:border-zinc-700/50 hover:bg-zinc-900/50 active:scale-[0.98] transition-all"
                        >
                          <div className="text-[10px] font-semibold text-zinc-400 truncate">{task.title}</div>
                        </button>
                      ))}
                      {slowNotImportant.length === 0 && (
                        <div className="text-center py-6 text-zinc-700 text-[10px]">{t('empty')}</div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="mt-4 flex justify-center gap-3 text-[10px] text-zinc-600">
              <button onClick={() => setActiveTab('list')} className="hover:text-zinc-400 transition-colors">
                {t('swipeLeftForList')}
              </button>
              <button onClick={() => setActiveTab('history')} className="hover:text-zinc-400 transition-colors">
                {t('swipeRightForHistory')}
              </button>
            </div>
          </motion.div>
        )}

        {activeTab === 'history' && (
          <motion.div
            key="history"
            custom={direction}
            initial={{ x: direction > 0 ? -300 : 300, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: direction > 0 ? 300 : -300, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            className="space-y-6">
            <div className="mb-4">
              <h1 className="text-2xl font-black mb-1.5 bg-gradient-to-r from-white via-zinc-100 to-zinc-300 bg-clip-text text-transparent tracking-tight">
                {t('allTasks')}
              </h1>
              <div className="text-[10px] text-zinc-700 font-semibold uppercase tracking-widest">{t('completeHistory')}</div>
            </div>

            <div className="space-y-2">
              {recentTasks.length > 0 ? (
                recentTasks.map(task => (
                  <div
                    key={task.id}
                    className={`p-3 rounded-xl border transition-all ${
                      task.completed
                        ? 'bg-zinc-900/40 border-zinc-800/40 opacity-60'
                        : 'bg-zinc-900/60 border-zinc-800/60'
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex-1">
                        <div className={`text-xs font-medium mb-1.5 ${task.completed ? 'line-through text-zinc-600' : 'text-white'}`}>
                          {task.title}
                        </div>
                        <div className="flex items-center gap-1.5 flex-wrap">
                          <span className={`text-[8px] px-1.5 py-0.5 rounded-md font-black border uppercase tracking-wider ${
                            task.importance_level === 'crucial' 
                              ? 'text-red-300 bg-red-950/60 border-red-800/60'
                              : task.importance_level === 'essential'
                              ? 'text-yellow-300 bg-yellow-950/60 border-yellow-800/60'
                              : 'text-blue-300 bg-blue-950/60 border-blue-800/60'
                          }`}>
                            {task.importance_level}
                          </span>
                          <span className="text-[8px] text-zinc-700 font-medium">
                            {task.time_duration?.replace(/_/g, ' ') || '1 hour'}
                          </span>
                          {task.completed && task.completed_date && (
                            <span className="text-[8px] text-green-600 font-medium">
                              ✓ {format(new Date(task.completed_date), 'MMM d')}
                            </span>
                          )}
                        </div>
                      </div>
                      {task.completed ? (
                        <button
                          onClick={() => uncompleteTaskMutation.mutate(task.id)}
                          className="p-1.5 hover:bg-zinc-800/50 rounded-lg transition-colors active:scale-95"
                        >
                          <CheckCircle2 className="w-4 h-4 text-green-600" />
                        </button>
                      ) : (
                        <button
                          onClick={() => completeTaskMutation.mutate(task.id)}
                          className="p-1.5 hover:bg-zinc-800/50 rounded-lg transition-colors active:scale-95"
                        >
                          <CheckCircle2 className="w-4 h-4 text-green-500" />
                        </button>
                      )}
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center py-12">
                  <div className="text-zinc-600 mb-1.5 text-sm">{t('noTasks')}</div>
                  <button
                    onClick={() => {
                      setActiveTab('list');
                      setShowAddForm(true);
                    }}
                    className="text-xs text-blue-400 hover:text-blue-300"
                  >
                    {t('addYourFirstTask')}
                  </button>
                </div>
              )}
            </div>

            <button
              onClick={() => setActiveTab('matrix')}
              className="mt-4 text-center text-[10px] text-zinc-600 hover:text-zinc-400 transition-colors w-full"
            >
              {t('swipeLeftToReturn')}
            </button>
          </motion.div>
        )}
        </AnimatePresence>
      </div>
    </div>
  );
}