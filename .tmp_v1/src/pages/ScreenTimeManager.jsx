import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery } from '@tanstack/react-query';
import { getTodayScreenTime, getAverageScreenTime, getOrCreateWinStreak } from '../components/businessLogic';
import { base44 } from '@/api/base44Client';
import { ArrowLeft, Target, Flame, Trophy, Crown, Ban, Zap, Shield } from 'lucide-react';
import { useLanguage } from '../components/LanguageProvider.jsx';

export default function ScreenTimeManager() {
  const { t } = useLanguage();
  const { data: todayScreenTime } = useQuery({
    queryKey: ['todayScreenTime'],
    queryFn: getTodayScreenTime
  });

  const { data: avgScreenTime } = useQuery({
    queryKey: ['avgScreenTime'],
    queryFn: () => getAverageScreenTime(7)
  });

  const { data: streak } = useQuery({
    queryKey: ['winStreak'],
    queryFn: getOrCreateWinStreak
  });

  const { data: rankData } = useQuery({
    queryKey: ['userRank'],
    queryFn: async () => {
      const user = await base44.auth.me();
      const ranks = await base44.entities.UserRank.filter({ created_by: user.email });
      return ranks[0];
    }
  });

  const { data: blockedApps } = useQuery({
    queryKey: ['blockedApps'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.BlockedApp.filter({ created_by: user.email });
    }
  });

  const { data: blockedSites } = useQuery({
    queryKey: ['blockedWebsites'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.BlockedWebsite.filter({ created_by: user.email });
    }
  });

  const isGoodUsage = (todayScreenTime || 0) <= 120;
  const isModerateUsage = (todayScreenTime || 0) > 120 && (todayScreenTime || 0) <= 240;

  return (
    <div className="min-h-screen bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white p-6 pt-20 pb-6 relative overflow-hidden">
      {/* Noise texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.015]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      <div className="max-w-2xl mx-auto relative">

        <div className="flex items-center justify-between mb-4">
          <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 transition-colors duration-150 active:scale-95">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-xs font-medium">{t('home')}</span>
          </Link>
          
          <h1 className="text-xl font-black bg-gradient-to-r from-white via-zinc-100 to-zinc-300 bg-clip-text text-transparent tracking-tight">
            {t('screenTime')}
          </h1>
          
          <div className="w-20" />
        </div>

        {/* FOCUS MODE - PRIMARY ACTION */}
        <div className="mb-4 relative animate-in fade-in zoom-in-95 duration-300">
          <div className="absolute inset-0 bg-gradient-to-r from-orange-500/40 to-red-500/40 rounded-[28px] blur-3xl opacity-80" />
          <Link
            to={createPageUrl('FocusMode')}
            className="relative block group"
          >
            <div className="p-5 rounded-[28px] bg-gradient-to-br from-orange-950/95 via-red-950/95 to-orange-950/95 backdrop-blur-xl border-2 border-orange-500/60 shadow-[0_24px_96px_rgba(249,115,22,0.6),inset_0_1px_0_rgba(255,255,255,0.05)] hover:shadow-[0_28px_112px_rgba(249,115,22,0.7)] active:scale-[0.98] transition-all duration-200">
              <div className="flex items-center justify-between">
                <div>
                  <div className="text-[9px] text-orange-400/60 font-black mb-1.5 uppercase tracking-widest">{t('startSession')}</div>
                  <div className="text-xl font-black mb-0.5 text-orange-100 tracking-tight">{t('focusMode')}</div>
                  <div className="text-[10px] text-orange-400/60 font-medium">{t('deepWorkEnvironment')}</div>
                </div>
                <div className="w-14 h-14 rounded-[18px] bg-gradient-to-br from-orange-500 to-red-600 flex items-center justify-center shadow-[0_16px_48px_rgba(249,115,22,0.6),inset_0_1px_0_rgba(255,255,255,0.2)] relative overflow-hidden">
                  <div className="absolute inset-0 bg-gradient-to-t from-white/0 to-white/30" />
                  <Zap className="w-7 h-7 text-white relative z-10 drop-shadow-[0_4px_8px_rgba(0,0,0,0.3)]" />
                </div>
              </div>
            </div>
          </Link>
        </div>

        {/* STATS CLUSTER - Grouped visual unit */}
        <div className="mb-4 relative animate-in fade-in zoom-in-95 duration-300 delay-75">
          <div className="absolute inset-0 bg-gradient-to-r from-zinc-700/10 to-zinc-600/10 rounded-[24px] blur-2xl" />
          <div className="relative p-4 rounded-[24px] bg-zinc-900/70 backdrop-blur-xl border border-zinc-800/50 shadow-[0_16px_64px_rgba(0,0,0,0.5),inset_0_1px_0_rgba(255,255,255,0.02)]">
            <div className="grid grid-cols-2 gap-3 mb-3">
              {/* Today's Usage - Bleu uniforme */}
              <div className="relative">
                <div className="absolute inset-0 rounded-xl blur-xl bg-blue-500/20 opacity-70 transition-all" />
                <div className="relative p-4 rounded-xl border-2 bg-blue-950/50 border-blue-700/50 transition-all shadow-[inset_0_2px_8px_rgba(0,0,0,0.3)]">
                  <div className="text-[8px] text-zinc-600 font-black uppercase tracking-widest mb-1.5">{t('today')}</div>
                  <div className="text-3xl font-black mb-0.5 text-blue-300">
                    {Math.round(todayScreenTime || 0)}
                  </div>
                  <div className="text-[9px] text-zinc-700 font-medium">minutes</div>
                </div>
              </div>

              {/* 7-Day Average */}
              <div className="relative">
                <div className="absolute inset-0 bg-zinc-600/15 rounded-xl blur-xl opacity-50" />
                <div className="relative p-4 rounded-xl bg-zinc-900/60 border border-zinc-800/50 shadow-[inset_0_2px_8px_rgba(0,0,0,0.3)]">
                  <div className="text-[8px] text-zinc-600 font-black uppercase tracking-widest mb-1.5">{t('avgUsage').split(' ')[0]}</div>
                  <div className="text-3xl font-black text-zinc-400 mb-0.5">
                    {Math.round(avgScreenTime || 0)}
                  </div>
                  <div className="text-[9px] text-zinc-700 font-medium">minutes</div>
                </div>
              </div>
            </div>

            {/* Rank & Streak - Inline */}
            <div className="grid grid-cols-2 gap-3">
              <Link to={createPageUrl('Rank')} className="group relative active:scale-[0.97] transition-all duration-150">
                <div className="absolute inset-0 bg-yellow-500/10 rounded-xl blur-lg opacity-40 group-hover:opacity-60 transition-opacity" />
                <div className="relative p-3 rounded-xl bg-zinc-900/50 border border-zinc-800/50 group-hover:border-zinc-700/60 transition-all">
                  <div className="flex items-center gap-2.5">
                    <Crown className="w-4 h-4 text-yellow-500/80" />
                    <div>
                      <div className="text-[8px] text-zinc-600 font-bold uppercase tracking-wider">{t('rank')}</div>
                      <div className="text-xs font-bold text-yellow-400">{rankData?.rank_name || 'Panda'}</div>
                    </div>
                  </div>
                </div>
              </Link>

              <Link to={createPageUrl('WinStreak')} className="group relative active:scale-[0.97] transition-all duration-150">
                <div className="absolute inset-0 bg-orange-500/10 rounded-xl blur-lg opacity-40 group-hover:opacity-60 transition-opacity" />
                <div className="relative p-3 rounded-xl bg-zinc-900/50 border border-zinc-800/50 group-hover:border-zinc-700/60 transition-all">
                  <div className="flex items-center gap-2.5">
                    <Flame className="w-4 h-4 text-orange-500/80" />
                    <div>
                      <div className="text-[8px] text-zinc-600 font-bold uppercase tracking-wider">{t('streak')}</div>
                      <div className="text-xs font-bold text-orange-400">{streak?.current_streak || 0}</div>
                    </div>
                  </div>
                </div>
              </Link>
            </div>
          </div>
        </div>

        {/* SECONDARY ACTIONS - Recessed */}
        <div className="space-y-2 mb-4">
          <Link
            to={createPageUrl('ScreenTime')}
            className="group relative block"
            >
            <div className="absolute inset-0 bg-blue-500/10 rounded-xl blur-lg opacity-30 group-hover:opacity-50 transition-opacity duration-200" />
            <div className="relative flex items-center justify-between p-4 rounded-xl bg-zinc-900/50 border border-zinc-800/50 group-hover:border-zinc-700/60 group-hover:bg-zinc-900/70 active:scale-[0.98] transition-all duration-150">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg relative">
                  {/* Base noire mate avec relief */}
                  <div className="absolute inset-0 rounded-lg"
                       style={{
                         background: '#2e2e2e',
                         boxShadow: `
                           0 2px 6px rgba(0, 0, 0, 0.35),
                           inset 0 1px 1px rgba(255, 255, 255, 0.03),
                           inset 0 -1px 1px rgba(0, 0, 0, 0.15)
                         `
                       }}
                  />
                  {/* Symbole d'interdiction tout en bleu */}
                  <div className="absolute inset-0 flex items-center justify-center">
                    <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none">
                      <circle cx="12" cy="12" r="9.5" stroke="#3b82f6" strokeWidth="1.8"/>
                      <line x1="6.5" y1="6.5" x2="17.5" y2="17.5" stroke="#3b82f6" strokeWidth="2.5" strokeLinecap="round"/>
                    </svg>
                  </div>
                </div>
                <div>
                  <div className="font-bold text-sm text-white mb-0.5">{t('blockApps')} & Sites</div>
                  <div className="text-[10px] text-zinc-600 font-medium">{(blockedApps?.length || 0) + (blockedSites?.length || 0)} {t('blocked')}</div>
                </div>
              </div>
              <div className="text-[10px] text-zinc-700">→</div>
            </div>
            </Link>

          <Link to={createPageUrl('Leaderboard')} className="group relative block">
            <div className="absolute inset-0 bg-blue-500/10 rounded-xl blur-lg opacity-30 group-hover:opacity-50 transition-opacity duration-200" />
            <div className="relative flex items-center justify-between p-4 rounded-xl bg-zinc-900/50 border border-zinc-800/50 group-hover:border-zinc-700/60 group-hover:bg-zinc-900/70 active:scale-[0.98] transition-all duration-150">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg relative">
                  {/* Base noire mate avec relief */}
                  <div className="absolute inset-0 rounded-lg"
                       style={{
                         background: '#2e2e2e',
                         boxShadow: `
                           0 2px 6px rgba(0, 0, 0, 0.35),
                           inset 0 1px 1px rgba(255, 255, 255, 0.03),
                           inset 0 -1px 1px rgba(0, 0, 0, 0.15)
                         `
                       }}
                  />
                  {/* Icône trophée tout en bleu */}
                  <div className="absolute inset-0 flex items-center justify-center">
                    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
                      <path d="M6 9H4.5a2.5 2.5 0 010-5H6" stroke="#3b82f6" strokeWidth="1.8" strokeLinecap="round"/>
                      <path d="M18 9h1.5a2.5 2.5 0 000-5H18" stroke="#3b82f6" strokeWidth="1.8" strokeLinecap="round"/>
                      <path d="M4 22h16" stroke="#3b82f6" strokeWidth="1.8" strokeLinecap="round"/>
                      <path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22" stroke="#3b82f6" strokeWidth="1.6" strokeLinecap="round"/>
                      <path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22" stroke="#3b82f6" strokeWidth="1.6" strokeLinecap="round"/>
                      <path d="M18 2H6v7a6 6 0 0012 0V2z" stroke="#3b82f6" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  </div>
                </div>
                <div>
                  <div className="font-bold text-sm text-white mb-0.5">{t('leaderboard')}</div>
                  <div className="text-[10px] text-zinc-600 font-medium">{t('globalRankings')}</div>
                </div>
              </div>
              <div className="text-[10px] text-zinc-700">→</div>
            </div>
          </Link>

          <Link to={createPageUrl('BlockingDemo')} className="group relative block">
            <div className="absolute inset-0 bg-blue-500/10 rounded-xl blur-lg opacity-30 group-hover:opacity-50 transition-opacity duration-200" />
            <div className="relative flex items-center justify-between p-4 rounded-xl bg-zinc-900/50 border border-zinc-800/50 group-hover:border-zinc-700/60 group-hover:bg-zinc-900/70 active:scale-[0.98] transition-all duration-150">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg relative">
                  <div className="absolute inset-0 rounded-lg"
                       style={{
                         background: '#2e2e2e',
                         boxShadow: `
                           0 2px 6px rgba(0, 0, 0, 0.35),
                           inset 0 1px 1px rgba(255, 255, 255, 0.03),
                           inset 0 -1px 1px rgba(0, 0, 0, 0.15)
                         `
                       }}
                  />
                  <div className="absolute inset-0 flex items-center justify-center">
                    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
                      <path d="M12 2.5L4.5 6.5v5.5c0 5.2 3.6 10.1 7.5 11.5 3.9-1.4 7.5-6.3 7.5-11.5V6.5L12 2.5z" 
                            stroke="#3b82f6" strokeWidth="1.9" strokeLinejoin="round"/>
                      <rect x="10" y="10" width="4" height="6" rx="0.5" stroke="#3b82f6" strokeWidth="2"/>
                    </svg>
                  </div>
                </div>
                <div>
                  <div className="font-bold text-sm text-white mb-0.5">Blocking Preview</div>
                  <div className="text-[10px] text-zinc-600 font-medium">See how blocking works</div>
                </div>
              </div>
              <div className="text-[10px] text-zinc-700">→</div>
            </div>
          </Link>
        </div>

        <div className="p-3 rounded-lg bg-zinc-950/60 border border-zinc-900/50 shadow-[inset_0_2px_8px_rgba(0,0,0,0.5)]">
          <div className="text-[9px] text-zinc-700 leading-relaxed font-medium">
            <span className="font-black text-zinc-600">{t('note')}:</span> {t('fullBlockingNote')}
          </div>
        </div>
      </div>
    </div>
  );
}