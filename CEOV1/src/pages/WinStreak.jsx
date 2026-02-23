import React from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery } from '@tanstack/react-query';
import { getOrCreateWinStreak } from '../components/businessLogic';
import { base44 } from '@/api/base44Client';
import { ArrowLeft, Flame, CheckCircle2, XCircle, Home, Trophy, TrendingUp } from 'lucide-react';
import { format } from 'date-fns';
import { useLanguage } from '../components/LanguageProvider';

export default function WinStreak() {
  const { t } = useLanguage();
  const { data: streak } = useQuery({
    queryKey: ['winStreak'],
    queryFn: getOrCreateWinStreak
  });

  const { data: recentSessions } = useQuery({
    queryKey: ['recentSessions'],
    queryFn: async () => {
      const user = await base44.auth.me();
      const sessions = await base44.entities.FocusSession.filter({ 
        created_by: user.email 
      }, '-created_date', 10);
      return sessions;
    },
    initialData: []
  });

  const { data: habitHistory } = useQuery({
    queryKey: ['habitHistory'],
    queryFn: async () => {
      const user = await base44.auth.me();
      const scores = await base44.entities.WeeklyHabitScore.filter({ 
        created_by: user.email 
      }, '-week_start_date', 10);
      return scores;
    },
    initialData: []
  });

  const currentStreak = streak?.current_streak || 0;
  const longestStreak = streak?.longest_streak || 0;
  const totalCompleted = streak?.total_completed_sessions || 0;
  const totalFailed = streak?.total_failed_sessions || 0;
  const successRate = totalCompleted + totalFailed > 0 
    ? Math.round((totalCompleted / (totalCompleted + totalFailed)) * 100)
    : 0;

  return (
    <div className="min-h-screen bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white p-6 pt-20 relative overflow-hidden">
      {/* Texture de fond */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.02]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      {/* Glow d'ambiance */}
      <div className="fixed top-0 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-gradient-to-b from-orange-500/20 via-red-500/10 to-transparent rounded-full blur-[120px] opacity-40 pointer-events-none" />

      <div className="max-w-2xl mx-auto relative">
        <div className="flex items-center justify-between mb-12">
          <Link to={createPageUrl('ScreenTimeManager')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 transition-colors active:scale-95">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-sm font-medium">Screen Time</span>
          </Link>
          <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 transition-colors active:scale-95">
            <Home className="w-4 h-4" />
            <span className="text-sm font-medium">Home</span>
          </Link>
        </div>

        {/* Hero Section - Current Streak */}
        <div className="relative mb-12">
          <div className="absolute inset-0 bg-gradient-to-r from-orange-500/30 to-red-500/30 rounded-[32px] blur-3xl opacity-70" />
          <div className="relative text-center p-12 rounded-[32px] bg-gradient-to-br from-zinc-900/90 via-zinc-850/90 to-zinc-900/90 backdrop-blur-xl border-2 border-orange-500/40 shadow-[0_24px_96px_rgba(249,115,22,0.4),inset_0_1px_0_rgba(255,255,255,0.05)]">
            <div className="mb-6 relative">
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="w-24 h-24 rounded-full bg-gradient-to-r from-orange-500/20 to-red-500/20 blur-2xl animate-pulse" />
              </div>
              <Flame className="relative w-20 h-20 mx-auto text-orange-500 drop-shadow-[0_0_20px_rgba(249,115,22,0.6)]" />
            </div>
            
            <div className="mb-3">
              <div className="text-xs text-orange-500/70 font-black mb-2 uppercase tracking-[0.2em]">Current Streak</div>
              <div className="text-[120px] leading-none font-black bg-gradient-to-br from-orange-200 via-orange-400 to-red-500 bg-clip-text text-transparent drop-shadow-[0_4px_20px_rgba(249,115,22,0.5)] tracking-tighter tabular-nums">
                {currentStreak}
              </div>
            </div>
            <div className="text-sm text-zinc-500 font-medium">
              {currentStreak === 0 ? 'Start your first session' : currentStreak === 1 ? '1 day of focus' : `${currentStreak} consecutive days`}
            </div>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-3 gap-4 mb-12">
          {/* Longest Streak */}
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-amber-500/20 to-yellow-500/20 rounded-2xl blur-xl opacity-60" />
            <div className="relative p-5 rounded-2xl bg-zinc-900/80 border border-amber-700/40 text-center backdrop-blur-sm shadow-[0_12px_40px_rgba(0,0,0,0.5)]">
              <Trophy className="w-6 h-6 mx-auto mb-3 text-amber-400" />
              <div className="text-3xl font-black bg-gradient-to-br from-amber-200 to-yellow-500 bg-clip-text text-transparent mb-1 tabular-nums">
                {longestStreak}
              </div>
              <div className="text-[9px] text-zinc-600 uppercase tracking-wider font-bold">Record</div>
            </div>
          </div>

          {/* Success Rate */}
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-green-500/20 to-emerald-500/20 rounded-2xl blur-xl opacity-60" />
            <div className="relative p-5 rounded-2xl bg-zinc-900/80 border border-green-700/40 text-center backdrop-blur-sm shadow-[0_12px_40px_rgba(0,0,0,0.5)]">
              <TrendingUp className="w-6 h-6 mx-auto mb-3 text-green-400" />
              <div className="text-3xl font-black bg-gradient-to-br from-green-200 to-emerald-400 bg-clip-text text-transparent mb-1 tabular-nums">
                {successRate}%
              </div>
              <div className="text-[9px] text-zinc-600 uppercase tracking-wider font-bold">Success</div>
            </div>
          </div>

          {/* Total Sessions */}
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-blue-500/20 to-purple-500/20 rounded-2xl blur-xl opacity-60" />
            <div className="relative p-5 rounded-2xl bg-zinc-900/80 border border-blue-700/40 text-center backdrop-blur-sm shadow-[0_12px_40px_rgba(0,0,0,0.5)]">
              <CheckCircle2 className="w-6 h-6 mx-auto mb-3 text-blue-400" />
              <div className="text-3xl font-black bg-gradient-to-br from-blue-200 to-purple-400 bg-clip-text text-transparent mb-1 tabular-nums">
                {totalCompleted}
              </div>
              <div className="text-[9px] text-zinc-600 uppercase tracking-wider font-bold">Complete</div>
            </div>
          </div>
        </div>

        {/* Habit Performance History */}
        {habitHistory && habitHistory.length > 0 && (
          <div className="relative mb-12">
            <div className="absolute inset-0 bg-gradient-to-r from-blue-500/15 to-purple-500/15 rounded-2xl blur-xl" />
            <div className="relative p-6 rounded-2xl bg-zinc-900/70 border border-zinc-700/50 shadow-[0_16px_64px_rgba(0,0,0,0.6)]">
              <h2 className="text-base font-black text-zinc-300 mb-5 tracking-tight uppercase">Habit Performance</h2>
              
              <div className="space-y-2">
                {habitHistory.map(score => (
                  <div
                    key={score.id}
                    className="p-4 rounded-xl bg-zinc-900/50 border border-zinc-800/50 hover:bg-zinc-900/70 transition-all"
                  >
                    <div className="flex items-center justify-between mb-2">
                      <div className="text-sm font-semibold text-white">
                        Week of {format(new Date(score.week_start_date), 'MMM d')}
                      </div>
                      <div className={`px-3 py-1.5 rounded-lg text-xs font-black ${
                        score.threshold_met
                          ? 'bg-green-950/40 text-green-300 border border-green-700/60'
                          : 'bg-red-950/40 text-red-300 border border-red-700/60'
                      }`}>
                        {Math.round(score.success_percentage)}%
                      </div>
                    </div>
                    <div className="flex items-center gap-2 text-xs text-zinc-500">
                      <span>{score.total_completed} / {score.total_expected} habits completed</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Recent Sessions */}
        <div className="relative">
          <div className="absolute inset-0 bg-gradient-to-r from-zinc-700/15 to-zinc-600/15 rounded-2xl blur-xl" />
          <div className="relative p-6 rounded-2xl bg-zinc-900/70 border border-zinc-700/50 shadow-[0_16px_64px_rgba(0,0,0,0.6)]">
            <h2 className="text-base font-black text-zinc-300 mb-5 tracking-tight uppercase">Recent Sessions</h2>
            
            <div className="space-y-2">
              {recentSessions && recentSessions.length > 0 ? (
                recentSessions.map(session => (
                  <div
                    key={session.id}
                    className={`p-4 rounded-xl border transition-all ${
                      session.completed
                        ? 'bg-green-950/30 border-green-800/50 hover:bg-green-950/40'
                        : 'bg-red-950/30 border-red-800/50 hover:bg-red-950/40'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        {session.completed ? (
                          <div className="relative">
                            <div className="absolute inset-0 bg-green-500/20 rounded-full blur-sm" />
                            <CheckCircle2 className="relative w-5 h-5 text-green-400" />
                          </div>
                        ) : (
                          <div className="relative">
                            <div className="absolute inset-0 bg-red-500/20 rounded-full blur-sm" />
                            <XCircle className="relative w-5 h-5 text-red-400" />
                          </div>
                        )}
                        <div>
                          <div className="text-sm font-semibold text-white">
                            {format(new Date(session.created_date), 'MMM d, yyyy')}
                          </div>
                          <div className="text-xs text-zinc-500 font-medium">
                            {session.actual_duration_minutes || session.duration_minutes} minutes
                          </div>
                        </div>
                      </div>
                      <div className={`px-3 py-1.5 rounded-lg border-2 text-xs font-black ${
                        session.completed 
                          ? 'text-green-300 bg-green-950/40 border-green-700/60' 
                          : 'text-red-300 bg-red-950/40 border-red-700/60'
                      }`}>
                        {session.completed ? '+1' : 'RESET'}
                      </div>
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center py-12 text-zinc-600 text-sm">
                  No sessions yet. Start your first focus session!
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Motivation Message */}
        {currentStreak > 0 && longestStreak > currentStreak && (
          <div className="mt-8 relative">
            <div className="absolute inset-0 bg-gradient-to-r from-blue-500/15 to-purple-500/15 rounded-xl blur-lg" />
            <div className="relative p-4 rounded-xl bg-zinc-900/60 border border-blue-700/30 text-center">
              <div className="text-sm text-blue-300 font-semibold">
                💡 Keep going! <span className="text-white font-black">{longestStreak - currentStreak}</span> more {longestStreak - currentStreak === 1 ? 'day' : 'days'} to beat your record.
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}