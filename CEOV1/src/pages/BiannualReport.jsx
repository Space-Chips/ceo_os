import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { ArrowLeft, ChevronRight, ChevronLeft } from 'lucide-react';
import { format, subDays, differenceInDays, startOfMonth, endOfMonth, eachMonthOfInterval } from 'date-fns';
import { useLanguage } from '../components/LanguageProvider';

export default function BiannualReport() {
  const [currentPage, setCurrentPage] = useState(0);

  const { data: reportData } = useQuery({
    queryKey: ['biannualReport'],
    queryFn: async () => {
      const user = await base44.auth.me();
      const sixMonthsAgo = subDays(new Date(), 180);
      const threeMonthsAgo = subDays(new Date(), 90);
      
      // Focus sessions
      const focusSessions = await base44.entities.FocusSession.filter({
        created_by: user.email
      });
      const recentSessions = focusSessions.filter(s => new Date(s.start_time) >= sixMonthsAgo);
      const firstHalf = focusSessions.filter(s => new Date(s.start_time) >= sixMonthsAgo && new Date(s.start_time) < threeMonthsAgo);
      const secondHalf = focusSessions.filter(s => new Date(s.start_time) >= threeMonthsAgo);
      const completedSessions = recentSessions.filter(s => s.completed);
      const totalFocusHours = completedSessions.reduce((sum, s) => sum + (s.duration_minutes / 60), 0);
      const firstHalfHours = firstHalf.filter(s => s.completed).reduce((sum, s) => sum + (s.duration_minutes / 60), 0);
      const secondHalfHours = secondHalf.filter(s => s.completed).reduce((sum, s) => sum + (s.duration_minutes / 60), 0);
      const focusTrend = firstHalfHours > 0 ? ((secondHalfHours - firstHalfHours) / firstHalfHours) * 100 : 0;
      
      // CEO mode sessions
      const ceoSessions = await base44.entities.CEOModeSession.filter({
        created_by: user.email
      });
      const recentCEO = ceoSessions.filter(s => new Date(s.start_time) >= sixMonthsAgo);
      const completedCEO = recentCEO.filter(s => s.end_time && !s.early_exit);
      const totalCEOHours = completedCEO.reduce((sum, s) => sum + (s.duration_minutes / 60), 0);
      
      // Win streak
      const streaks = await base44.entities.WinStreak.filter({ created_by: user.email });
      const streak = streaks[0];
      
      // Rank
      const ranks = await base44.entities.UserRank.filter({ created_by: user.email });
      const rank = ranks[0];
      
      // Habits
      const habits = await base44.entities.Habit.filter({ 
        created_by: user.email,
        archived: false
      });
      
      // Habit completions
      const completions = await base44.entities.HabitCompletion.filter({
        created_by: user.email
      });
      const recentCompletions = completions.filter(c => new Date(c.date) >= sixMonthsAgo && c.completed);
      const firstHalfCompletions = completions.filter(c => new Date(c.date) >= sixMonthsAgo && new Date(c.date) < threeMonthsAgo && c.completed);
      const secondHalfCompletions = completions.filter(c => new Date(c.date) >= threeMonthsAgo && c.completed);
      
      // Habit success by category
      const objectives = await base44.entities.Objective.filter({ 
        created_by: user.email,
        archived: false
      });
      
      const categoryStats = {};
      for (const obj of objectives) {
        const objHabits = habits.filter(h => h.objective_id === obj.id);
        const objCompletions = recentCompletions.filter(c => 
          objHabits.some(h => h.id === c.habit_id)
        );
        const expectedCount = objHabits.length * 180;
        const rate = expectedCount > 0 ? (objCompletions.length / expectedCount) * 100 : 0;
        categoryStats[obj.title] = Math.round(rate);
      }
      
      // Calculate habit success rate
      const daysActive = Math.min(180, differenceInDays(new Date(), new Date(user.created_date)));
      const expectedCompletions = habits.length * daysActive;
      const habitSuccessRate = expectedCompletions > 0 ? (recentCompletions.length / expectedCompletions) * 100 : 0;
      
      const firstHalfExpected = habits.length * 90;
      const secondHalfExpected = habits.length * 90;
      const firstHalfRate = firstHalfExpected > 0 ? (firstHalfCompletions.length / firstHalfExpected) * 100 : 0;
      const secondHalfRate = secondHalfExpected > 0 ? (secondHalfCompletions.length / secondHalfExpected) * 100 : 0;
      const habitTrend = firstHalfRate > 0 ? secondHalfRate - firstHalfRate : 0;
      
      // Pareto tasks
      const paretoTasks = await base44.entities.ParetoTask.filter({
        created_by: user.email,
        completed: true
      });
      const recentTasks = paretoTasks.filter(t => t.completed_date && new Date(t.completed_date) >= sixMonthsAgo);
      const firstHalfTasks = paretoTasks.filter(t => t.completed_date && new Date(t.completed_date) >= sixMonthsAgo && new Date(t.completed_date) < threeMonthsAgo);
      const secondHalfTasks = paretoTasks.filter(t => t.completed_date && new Date(t.completed_date) >= threeMonthsAgo);
      
      // Productivity Index from Pareto Matrix
      const crucialShort = recentTasks.filter(t => t.importance_level === 'crucial' && (t.time_duration === 'less_than_30min' || t.time_duration === '1_hour')).length;
      const crucialLong = recentTasks.filter(t => t.importance_level === 'crucial' && (t.time_duration === '2_hours' || t.time_duration === 'half_day' || t.time_duration === '1_day' || t.time_duration === 'several_days')).length;
      const essentialShort = recentTasks.filter(t => t.importance_level === 'essential' && (t.time_duration === 'less_than_30min' || t.time_duration === '1_hour')).length;
      const essentialLong = recentTasks.filter(t => t.importance_level === 'essential' && (t.time_duration === '2_hours' || t.time_duration === 'half_day' || t.time_duration === '1_day' || t.time_duration === 'several_days')).length;
      const lowPriority = recentTasks.filter(t => t.importance_level === 'average' || t.importance_level === 'low').length;
      
      const totalTasks = recentTasks.length;
      const highImpactScore = totalTasks > 0 ? ((crucialShort + crucialLong + essentialShort + essentialLong) / totalTasks) * 100 : 0;
      const quickWinsScore = totalTasks > 0 ? (crucialShort / totalTasks) * 100 : 0;
      
      const paretoTaskTrend = firstHalfTasks.length > 0 ? ((secondHalfTasks.length - firstHalfTasks.length) / firstHalfTasks.length) * 100 : 0;
      
      // Screen Time
      const screenLogs = await base44.entities.ScreenTimeLog.filter({
        created_by: user.email
      });
      const recentLogs = screenLogs.filter(l => new Date(l.date) >= sixMonthsAgo);
      const totalScreenSeconds = recentLogs.reduce((sum, l) => sum + l.duration_seconds, 0);
      const avgDailyMinutes = (totalScreenSeconds / 60) / 180;
      const avgWeeklyHours = (avgDailyMinutes * 7) / 60;
      
      // Life projection
      const yearsRemaining = 80 - (new Date().getFullYear() - new Date(user.created_date).getFullYear());
      const lifetimeScreenHours = (avgDailyMinutes * 365 * yearsRemaining) / 60;
      const lifetimeScreenYears = lifetimeScreenHours / 8760; // hours in a year
      
      // Category breakdown
      const categoryBreakdown = {};
      recentLogs.forEach(log => {
        const category = log.is_social_media ? 'Social Media' : 'Other';
        if (!categoryBreakdown[category]) categoryBreakdown[category] = 0;
        categoryBreakdown[category] += log.duration_seconds / 3600;
      });
      
      // Generate dominant insight
      const insights = [];
      
      if (habitTrend < -15) {
        insights.push({ priority: 1, text: `Habit consistency declined ${Math.abs(Math.round(habitTrend))}%. Recommit to one core habit this week.` });
      } else if (habitTrend > 15) {
        insights.push({ priority: 2, text: `Habit execution improved ${Math.round(habitTrend)}%. Maintain this momentum.` });
      }
      
      if (highImpactScore < 50) {
        insights.push({ priority: 1, text: `Only ${Math.round(highImpactScore)}% of tasks are high-impact. Eliminate low-priority work.` });
      } else if (highImpactScore > 80) {
        insights.push({ priority: 2, text: `${Math.round(highImpactScore)}% high-impact focus maintained. You're optimizing well.` });
      }
      
      if (focusTrend < -20) {
        insights.push({ priority: 1, text: `Deep work decreased ${Math.abs(Math.round(focusTrend))}%. Schedule protected focus blocks.` });
      }
      
      if (avgDailyMinutes > 180 && categoryBreakdown['Social Media'] > totalScreenSeconds / 7200) {
        insights.push({ priority: 1, text: `Screen time high at ${Math.round(avgDailyMinutes)}m/day. Block social media during work hours.` });
      }
      
      if (paretoTaskTrend > 30) {
        insights.push({ priority: 2, text: `Task velocity increased ${Math.round(paretoTaskTrend)}%. Keep shipping.` });
      }
      
      const dominantInsight = insights.sort((a, b) => a.priority - b.priority)[0]?.text || 'Continue building consistency across all areas.';
      
      return {
        totalFocusHours: Math.round(totalFocusHours),
        totalCEOHours: Math.round(totalCEOHours),
        currentStreak: streak?.current_streak || 0,
        longestStreak: streak?.longest_streak || 0,
        rankName: rank?.rank_name || 'Bronze',
        rankLevel: rank?.rank_level || 1,
        habitSuccessRate: Math.round(habitSuccessRate),
        totalHabits: habits.length,
        completedTasks: recentTasks.length,
        daysActive,
        categoryStats,
        productivityIndex: Math.round(highImpactScore),
        quickWinsRate: Math.round(quickWinsScore),
        avgDailyScreenMinutes: Math.round(avgDailyMinutes),
        avgWeeklyScreenHours: Math.round(avgWeeklyScreenHours * 10) / 10,
        lifetimeScreenYears: Math.round(lifetimeScreenYears * 10) / 10,
        lifetimeScreenHours: Math.round(lifetimeScreenHours),
        categoryBreakdown,
        paretoBreakdown: {
          crucialShort,
          crucialLong,
          essentialShort,
          essentialLong,
          lowPriority
        },
        focusTrend: Math.round(focusTrend),
        habitTrend: Math.round(habitTrend),
        paretoTaskTrend: Math.round(paretoTaskTrend),
        dominantInsight,
        totalCompletedSessions: completedSessions.length,
        totalCEOSessions: completedCEO.length
      };
    }
  });

  const { t } = useLanguage();

  const pages = [
    {
      id: 'executive',
      title: t('executiveSnapshot'),
      subtitle: t('last6Months')
    },
    {
      id: 'trends',
      title: t('trendEvolution'),
      subtitle: t('first90VsLast90')
    },
    {
      id: 'habits',
      title: t('habitsConsistency'),
      subtitle: t('performanceByObjective')
    },
    {
      id: 'focus',
      title: t('focusDiscipline'),
      subtitle: t('deepWorkPatterns')
    },
    {
      id: 'pareto',
      title: t('paretoPriorities'),
      subtitle: t('taskImpactDistribution')
    },
    {
      id: 'insight',
      title: t('keyInsight'),
      subtitle: t('whatMattersMost')
    }
  ];

  const nextPage = () => setCurrentPage((prev) => Math.min(prev + 1, pages.length - 1));
  const prevPage = () => setCurrentPage((prev) => Math.max(prev - 1, 0));

  const renderPage = () => {
    const page = pages[currentPage];
    
    if (page.id === 'executive') {
      return (
        <div className="space-y-12">
          <div className="text-center">
            <div className="text-7xl mb-4">
              {reportData?.rankName === 'Bronze' && '🥉'}
              {reportData?.rankName === 'Silver' && '🥈'}
              {reportData?.rankName === 'Gold' && '🥇'}
              {reportData?.rankName === 'Platinum' && '💎'}
              {reportData?.rankName === 'Diamond' && '💠'}
              {reportData?.rankName === 'Batman' && '🦇'}
              {reportData?.rankName === 'CEO' && '👑'}
            </div>
            <div className="text-4xl font-bold mb-2">{reportData?.rankName || 'Bronze'}</div>
            <div className="text-sm text-zinc-600">{t('currentRank')}</div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="p-6 rounded-2xl bg-zinc-900/60 border border-zinc-800/40">
              <div className="text-4xl font-bold mb-1">{reportData?.totalFocusHours || 0}h</div>
              <div className="text-xs text-zinc-500 uppercase tracking-wider">{t('deepWork')}</div>
            </div>
            
            <div className="p-6 rounded-2xl bg-zinc-900/60 border border-zinc-800/40">
              <div className="text-4xl font-bold mb-1">{reportData?.habitSuccessRate || 0}%</div>
              <div className="text-xs text-zinc-500 uppercase tracking-wider">{t('habits')}</div>
            </div>
            
            <div className="p-6 rounded-2xl bg-zinc-900/60 border border-zinc-800/40">
              <div className="text-4xl font-bold mb-1">{reportData?.productivityIndex || 0}%</div>
              <div className="text-xs text-zinc-500 uppercase tracking-wider">{t('highImpact')}</div>
            </div>
            
            <div className="p-6 rounded-2xl bg-zinc-900/60 border border-zinc-800/40">
              <div className="text-4xl font-bold mb-1">{reportData?.completedTasks || 0}</div>
              <div className="text-xs text-zinc-500 uppercase tracking-wider">{t('tasksDone')}</div>
            </div>
          </div>
        </div>
      );
    }
    
    if (page.id === 'trends') {
      return (
        <div className="space-y-8">
          <div className="p-6 rounded-2xl bg-zinc-900/60 border border-zinc-800/40">
            <div className="flex items-baseline justify-between mb-2">
              <div className="text-sm text-zinc-500 uppercase tracking-wider">{t('deepWork')}</div>
              <div className={`text-2xl font-bold ${reportData?.focusTrend >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                {reportData?.focusTrend >= 0 ? '+' : ''}{reportData?.focusTrend || 0}%
              </div>
            </div>
            <div className="text-xs text-zinc-600">{t('vsPrevious3Months')}</div>
          </div>

          <div className="p-6 rounded-2xl bg-zinc-900/60 border border-zinc-800/40">
            <div className="flex items-baseline justify-between mb-2">
              <div className="text-sm text-zinc-500 uppercase tracking-wider">{t('habitExecution')}</div>
              <div className={`text-2xl font-bold ${reportData?.habitTrend >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                {reportData?.habitTrend >= 0 ? '+' : ''}{reportData?.habitTrend || 0}%
              </div>
            </div>
            <div className="text-xs text-zinc-600">{t('vsPrevious3Months')}</div>
          </div>

          <div className="p-6 rounded-2xl bg-zinc-900/60 border border-zinc-800/40">
            <div className="flex items-baseline justify-between mb-2">
              <div className="text-sm text-zinc-500 uppercase tracking-wider">{t('taskVelocity')}</div>
              <div className={`text-2xl font-bold ${reportData?.paretoTaskTrend >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                {reportData?.paretoTaskTrend >= 0 ? '+' : ''}{reportData?.paretoTaskTrend || 0}%
              </div>
            </div>
            <div className="text-xs text-zinc-600">{t('vsPrevious3Months')}</div>
          </div>
        </div>
      );
    }
    
    if (page.id === 'habits') {
      return (
        <div className="space-y-6">
          <div className="text-center mb-8">
            <div className="text-5xl font-bold mb-2">{reportData?.habitSuccessRate || 0}%</div>
            <div className="text-sm text-zinc-600">{t('overallCompletionRate')}</div>
          </div>

          <div className="space-y-3">
            {reportData?.categoryStats && Object.entries(reportData.categoryStats)
              .sort((a, b) => b[1] - a[1])
              .map(([category, rate]) => (
                <div key={category} className="p-4 rounded-xl bg-zinc-900/60 border border-zinc-800/40">
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-sm font-medium text-zinc-300">{category}</span>
                    <span className={`text-xl font-bold ${rate >= 80 ? 'text-green-400' : rate >= 60 ? 'text-yellow-400' : 'text-red-400'}`}>
                      {rate}%
                    </span>
                  </div>
                  <div className="h-1.5 bg-zinc-950 rounded-full overflow-hidden">
                    <div 
                      className={`h-full transition-all ${rate >= 80 ? 'bg-green-500' : rate >= 60 ? 'bg-yellow-500' : 'bg-red-500'}`}
                      style={{ width: `${rate}%` }}
                    />
                  </div>
                </div>
              ))}
          </div>
        </div>
      );
    }
    
    if (page.id === 'focus') {
      return (
        <div className="space-y-8">
          <div className="grid grid-cols-2 gap-4">
            <div className="p-6 rounded-2xl bg-zinc-900/60 border border-zinc-800/40">
              <div className="text-4xl font-bold mb-2">{reportData?.totalCompletedSessions || 0}</div>
              <div className="text-xs text-zinc-500 uppercase tracking-wider">{t('focusSessions')}</div>
            </div>
            
            <div className="p-6 rounded-2xl bg-zinc-900/60 border border-zinc-800/40">
              <div className="text-4xl font-bold mb-2">{reportData?.currentStreak || 0}</div>
              <div className="text-xs text-zinc-500 uppercase tracking-wider">{t('winStreak')}</div>
            </div>
          </div>

          <div className="p-6 rounded-2xl bg-zinc-900/60 border border-zinc-800/40">
            <div className="text-sm text-zinc-500 uppercase tracking-wider mb-4">{t('screenTime')}</div>
            <div className="text-3xl font-bold mb-1">{reportData?.avgDailyScreenMinutes || 0}m</div>
            <div className="text-xs text-zinc-600">{t('dailyAverage')}</div>
          </div>

          {reportData?.totalCEOHours > 0 && (
            <div className="p-6 rounded-2xl bg-zinc-900/60 border border-zinc-800/40">
              <div className="text-sm text-zinc-500 uppercase tracking-wider mb-4">{t('ceoMode')}</div>
              <div className="text-3xl font-bold mb-1">{reportData?.totalCEOHours || 0}h</div>
              <div className="text-xs text-zinc-600">{t('maximumFocusHours')}</div>
            </div>
          )}
        </div>
      );
    }
    
    if (page.id === 'pareto') {
      return (
        <div className="space-y-8">
          <div className="text-center mb-8">
            <div className="text-5xl font-bold mb-2">{reportData?.productivityIndex || 0}%</div>
            <div className="text-sm text-zinc-600">{t('highImpactWork')}</div>
          </div>

          <div className="space-y-3 text-sm">
            <div className="flex items-center justify-between p-4 rounded-xl bg-zinc-900/60 border border-zinc-800/40">
              <span className="text-zinc-400">{t('crucial')}</span>
              <span className="text-xl font-bold">{(reportData?.paretoBreakdown?.crucialShort || 0) + (reportData?.paretoBreakdown?.crucialLong || 0)}</span>
            </div>
            <div className="flex items-center justify-between p-4 rounded-xl bg-zinc-900/60 border border-zinc-800/40">
              <span className="text-zinc-400">{t('essential')}</span>
              <span className="text-xl font-bold">{(reportData?.paretoBreakdown?.essentialShort || 0) + (reportData?.paretoBreakdown?.essentialLong || 0)}</span>
            </div>
            <div className="flex items-center justify-between p-4 rounded-xl bg-zinc-900/60 border border-zinc-800/40 opacity-40">
              <span className="text-zinc-600">{t('lowPriority')}</span>
              <span className="text-xl font-bold text-zinc-600">{reportData?.paretoBreakdown?.lowPriority || 0}</span>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-green-950/20 border border-green-900/40">
            <div className="text-xs text-green-400">
              {t('quickWins')}: <span className="font-bold">{reportData?.quickWinsRate || 0}%</span> {t('ofTasks')}
            </div>
          </div>
        </div>
      );
    }
    
    if (page.id === 'insight') {
      return (
        <div className="space-y-8">
          <div className="p-8 rounded-2xl bg-zinc-900/60 border border-zinc-800/40">
            <div className="text-sm text-zinc-600 uppercase tracking-wider mb-6">{t('dominantInsight')}</div>
            <div className="text-lg leading-relaxed text-zinc-200">
              {reportData?.dominantInsight || 'Continue building consistency across all areas.'}
            </div>
          </div>

          <div className="p-6 rounded-2xl bg-zinc-900/40 border border-zinc-800/30">
            <div className="text-xs text-zinc-600 uppercase tracking-wider mb-3">{t('reportPeriod')}</div>
            <div className="text-sm text-zinc-400">
              {reportData?.daysActive || 0} {t('daysTracked')}
            </div>
          </div>
        </div>
      );
    }
  };

  return (
    <div className="min-h-screen bg-black text-white p-6 flex flex-col">
      <div className="max-w-2xl mx-auto w-full flex-1 flex flex-col">
        <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-400 mb-8 transition-colors">
          <ArrowLeft className="w-4 h-4" />
          <span className="text-sm font-medium">{t('home')}</span>
        </Link>

        <div className="text-center mb-12">
          <h1 className="text-3xl font-bold mb-2 text-zinc-100">
            {pages[currentPage].title}
          </h1>
          <p className="text-sm text-zinc-600">{pages[currentPage].subtitle}</p>
        </div>

        <div className="flex-1 flex items-center justify-center">
          {renderPage()}
        </div>

        <div className="mt-12 flex items-center justify-between">
          <button
            onClick={prevPage}
            disabled={currentPage === 0}
            className="p-3 rounded-xl bg-zinc-900/60 border border-zinc-800/40 disabled:opacity-30 disabled:cursor-not-allowed hover:bg-zinc-900 transition-all"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>

          <div className="flex gap-1.5">
            {pages.map((_, idx) => (
              <button
                key={idx}
                onClick={() => setCurrentPage(idx)}
                className={`h-1.5 rounded-full transition-all ${
                  idx === currentPage ? 'w-8 bg-zinc-400' : 'w-1.5 bg-zinc-800'
                }`}
              />
            ))}
          </div>

          <button
            onClick={nextPage}
            disabled={currentPage === pages.length - 1}
            className="p-3 rounded-xl bg-zinc-900/60 border border-zinc-800/40 disabled:opacity-30 disabled:cursor-not-allowed hover:bg-zinc-900 transition-all"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}