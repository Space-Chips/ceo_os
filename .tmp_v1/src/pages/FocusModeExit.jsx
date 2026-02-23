import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { ArrowLeft, AlertTriangle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { exitFocusSessionEarly, getOrCreateWinStreak } from '../components/businessLogic';
import { useLanguage } from '../components/LanguageProvider';

export default function FocusModeExit() {
  const { t } = useLanguage();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const { data: activeSession } = useQuery({
    queryKey: ['activeSession'],
    queryFn: async () => {
      const user = await base44.auth.me();
      const sessions = await base44.entities.FocusSession.filter({
        created_by: user.email,
        completed: false,
        early_exit: false
      });
      return sessions.length > 0 ? sessions[0] : null;
    }
  });

  const { data: streak } = useQuery({
    queryKey: ['winStreak'],
    queryFn: getOrCreateWinStreak
  });

  const exitMutation = useMutation({
    mutationFn: async () => {
      if (activeSession) {
        await exitFocusSessionEarly(activeSession.id);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['activeSession']);
      queryClient.invalidateQueries(['winStreak']);
      navigate(createPageUrl('Home'));
    }
  });

  if (!activeSession) {
    navigate(createPageUrl('Home'));
    return null;
  }

  return (
    <div className="min-h-screen bg-black text-white p-6 pt-20 flex flex-col items-center justify-center relative overflow-hidden">
      <div className="max-w-md w-full">
        <Link to={createPageUrl('ScreenTimeManager')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 mb-12 transition-colors">
          <ArrowLeft className="w-4 h-4" />
          <span className="text-sm font-medium">{t('back')}</span>
        </Link>

        <div className="text-center mb-12">
          <div className="mb-8">
            <div className="w-20 h-20 mx-auto rounded-full bg-red-950/60 border-2 border-red-500/50 flex items-center justify-center mb-4">
              <AlertTriangle className="w-10 h-10 text-red-400" />
            </div>
          </div>
          <h1 className="text-3xl font-black text-white mb-4 tracking-tight">
            {t('exitFocusMode')}
          </h1>
          <p className="text-base text-zinc-400 mb-2 leading-relaxed">
            {t('thisWillReset')} <span className="text-red-400 font-bold">{streak?.current_streak || 0}{t('dayWinStreak')}</span> {t('toZero')}.
          </p>
        </div>

        <div className="space-y-3">
          <Button
            onClick={() => navigate(createPageUrl('FocusMode'))}
            className="w-full bg-white text-black hover:bg-zinc-200 h-14 text-base font-black rounded-2xl shadow-[0_12px_48px_rgba(255,255,255,0.15)] active:scale-[0.97] transition-all"
          >
            {t('stayFocused')}
          </Button>

          <Button
            onClick={() => exitMutation.mutate()}
            disabled={exitMutation.isPending}
            className="w-full bg-transparent border border-red-900/50 text-red-500 hover:bg-red-950/30 hover:border-red-900/70 h-12 font-semibold rounded-2xl active:scale-[0.98] transition-all"
          >
            {exitMutation.isPending ? 'Exiting...' : t('yesExit')}
          </Button>
        </div>
      </div>
    </div>
  );
}