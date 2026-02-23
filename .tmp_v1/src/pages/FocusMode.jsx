import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { startFocusSession, completeFocusSession, exitFocusSessionEarly, getOrCreateWinStreak } from '../functions/businessLogic';
import { base44 } from '@/api/base44Client';
import { ArrowLeft, Target, AlertTriangle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { differenceInSeconds, parseISO } from 'date-fns';
import { useLanguage } from '../components/LanguageProvider.jsx';
import { usePremium } from '../components/PremiumProvider';
import { canStartFocusSession, PREMIUM_LIMITS } from '../components/premiumLimits';
import PremiumGate from '../components/PremiumGate';
import CooldownScreen from '../components/blocking/CooldownScreen';

export default function FocusMode() {
  const { t } = useLanguage();
  const { isPremiumUser } = usePremium();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [duration, setDuration] = useState(45);
  const [activeSession, setActiveSession] = useState(null);
  const [timeRemaining, setTimeRemaining] = useState(0);
  const [showExitConfirm, setShowExitConfirm] = useState(false);
  const [premiumBlock, setPremiumBlock] = useState(null);

  const { data: streak } = useQuery({
    queryKey: ['winStreak'],
    queryFn: getOrCreateWinStreak
  });

  const { data: activeSessions } = useQuery({
    queryKey: ['activeSessions'],
    queryFn: async () => {
      const user = await base44.auth.me();
      const sessions = await base44.entities.FocusSession.filter({ 
        created_by: user.email,
        completed: false,
        early_exit: false
      }, '-created_date', 1);
      
      if (sessions.length > 0) {
        const session = sessions[0];
        const elapsed = differenceInSeconds(new Date(), parseISO(session.start_time));
        const total = session.duration_minutes * 60;
        if (elapsed < total) {
          return session;
        }
      }
      return null;
    }
  });

  useEffect(() => {
    if (activeSessions) {
      setActiveSession(activeSessions);
    }
  }, [activeSessions]);

  useEffect(() => {
    if (activeSession) {
      const interval = setInterval(() => {
        const elapsed = differenceInSeconds(new Date(), parseISO(activeSession.start_time));
        const total = activeSession.duration_minutes * 60;
        const remaining = Math.max(0, total - elapsed);
        
        setTimeRemaining(remaining);
        
        if (remaining === 0) {
          completeMutation.mutate(activeSession.id);
        }
      }, 1000);
      
      return () => clearInterval(interval);
    }
  }, [activeSession]);

  const startMutation = useMutation({
    mutationFn: async (mins) => {
      // Vérifier les limites premium
      const check = await canStartFocusSession(isPremiumUser, mins);
      if (!check.allowed) {
        setPremiumBlock(check);
        throw new Error('Premium limit reached');
      }

      const session = await startFocusSession(mins);
      return session;
    },
    onSuccess: (session) => {
      setActiveSession(session);
      queryClient.invalidateQueries(['activeSessions']);
      setPremiumBlock(null);
    },
    onError: (error) => {
      if (error.message !== 'Premium limit reached') {
        console.error('Focus session error:', error);
      }
    }
  });

  const completeMutation = useMutation({
    mutationFn: completeFocusSession,
    onSuccess: (result) => {
      queryClient.invalidateQueries(['winStreak']);
      queryClient.invalidateQueries(['activeSessions']);
      setActiveSession(null);
      // Show success state briefly before allowing navigation
      setTimeout(() => {
        navigate(createPageUrl('Home'));
      }, 3000);
    }
  });

  const exitMutation = useMutation({
    mutationFn: exitFocusSessionEarly,
    onSuccess: () => {
      queryClient.invalidateQueries(['winStreak']);
      queryClient.invalidateQueries(['activeSessions']);
      setActiveSession(null);
      setShowCooldown(false);
      navigate(createPageUrl('Home'));
    }
  });

  const [showCooldown, setShowCooldown] = useState(false);

  const handleExit = () => {
    setShowExitConfirm(true);
  };

  const confirmExit = () => {
    setShowExitConfirm(false);
    setShowCooldown(true);
  };

  const handleCooldownComplete = () => {
    exitMutation.mutate(activeSession.id);
  };

  const handleCooldownCancel = () => {
    setShowCooldown(false);
  };

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const getProgress = () => {
    if (!activeSession) return 0;
    const total = activeSession.duration_minutes * 60;
    const elapsed = total - timeRemaining;
    return (elapsed / total) * 100;
  };

  // Session complete state
  if (completeMutation.isSuccess) {
    return (
      <div className="min-h-screen bg-black text-white flex items-center justify-center p-6">
        <div className="text-center max-w-md">
          <div className="text-6xl mb-6">⭐</div>
          <h1 className="text-3xl font-bold mb-4">{t('sessionComplete')}</h1>
          <div className="text-6xl font-bold text-green-500 mb-2">
            🔥 {(streak?.current_streak || 0) + 1}
          </div>
          <div className="text-gray-400 mb-8">{t('winStreak')}</div>
          <div className="text-sm text-gray-500">{t('returningHome')}</div>
        </div>
      </div>
    );
  }

  // Active session state
  if (activeSession && timeRemaining > 0) {
    if (showCooldown) {
      return (
        <CooldownScreen
          onComplete={handleCooldownComplete}
          onCancel={handleCooldownCancel}
          message="Exiting Focus Mode..."
        />
      );
    }

    return (
      <div className="min-h-screen bg-gradient-to-b from-black to-gray-900 text-white flex flex-col items-center justify-center p-6">
        {showExitConfirm ? (
          <div className="max-w-md w-full">
            <div className="bg-gray-900 border border-red-900 rounded-2xl p-8">
              <AlertTriangle className="w-12 h-12 text-red-500 mx-auto mb-4" />
              <h2 className="text-2xl font-bold text-center mb-4">{t('exitFocusMode')}</h2>
              <p className="text-gray-400 text-center mb-2">
                {t('thisWillReset')}
              </p>
              <p className="text-3xl font-bold text-red-500 text-center mb-6">
                {streak?.current_streak || 0}{t('dayWinStreak')}
              </p>
              <p className="text-gray-400 text-center mb-8">{t('toZero')}</p>
              <div className="flex gap-3">
                <Button
                  onClick={() => setShowExitConfirm(false)}
                  variant="outline"
                  className="flex-1 bg-transparent border-gray-700 hover:bg-gray-800"
                >
                  {t('stayFocused')}
                </Button>
                <Button
                  onClick={confirmExit}
                  className="flex-1 bg-red-600 hover:bg-red-700"
                >
                  {t('yesExit')}
                </Button>
              </div>
            </div>
          </div>
        ) : (
          <>
            <Target className="w-16 h-16 text-purple-500 mb-8" />
            <div className="text-8xl font-bold mb-8 tabular-nums">
              {formatTime(timeRemaining)}
            </div>
            <div className="w-full max-w-md mb-8">
              <div className="h-2 bg-gray-800 rounded-full overflow-hidden">
                <div 
                  className="h-full bg-gradient-to-r from-purple-600 to-purple-400 transition-all duration-1000"
                  style={{ width: `${getProgress()}%` }}
                />
              </div>
            </div>
            <p className="text-gray-400 mb-16 text-center">{t('stayFocusedMsg')}</p>
            <button
              onClick={handleExit}
              className="text-sm text-gray-600 hover:text-gray-400 transition-colors"
            >
              {t('exitSession')}
            </button>
          </>
        )}
      </div>
    );
  }

  // Bloquer si limite premium atteinte
  if (premiumBlock) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white p-6 pt-20 relative">
        <div className="max-w-md mx-auto">
          <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 mb-8 transition-colors">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-sm font-medium">{t('home')}</span>
          </Link>
          
          <PremiumGate
            feature={premiumBlock.reason}
            limit={premiumBlock.limit}
            current={premiumBlock.current}
          >
            {null}
          </PremiumGate>
        </div>
      </div>
    );
  }

  // Session setup state
  return (
    <div className="min-h-screen bg-black text-white p-6">
      <div className="max-w-md mx-auto">
        <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-gray-400 mb-8">
          <ArrowLeft className="w-4 h-4" />
          <span className="text-sm">{t('home')}</span>
        </Link>

        <div className="text-center mb-12">
          <Target className="w-16 h-16 mx-auto mb-6 text-purple-500" />
          <h1 className="text-3xl font-bold mb-4">{t('enterTheZone')}</h1>
          <p className="text-gray-400">{t('selectDuration')}</p>
        </div>

        <div className="grid grid-cols-3 gap-3 mb-8">
          {[25, 45, 90].map(mins => {
            const isDisabled = !isPremiumUser && mins > PREMIUM_LIMITS.FOCUS_MAX_DURATION_MINUTES;
            
            return (
              <button
                key={mins}
                onClick={() => !isDisabled && setDuration(mins)}
                disabled={isDisabled}
                className={`p-6 rounded-xl border transition-all ${
                  duration === mins
                    ? 'bg-purple-600 border-purple-500'
                    : isDisabled
                    ? 'bg-gray-950 border-gray-900 opacity-40 cursor-not-allowed'
                    : 'bg-gray-900 border-gray-800 hover:border-gray-700'
                }`}
              >
                <div className="text-2xl font-bold">{mins}</div>
                <div className="text-xs text-gray-400">{t('min')}</div>
              </button>
            );
          })}
        </div>

        <div className="mb-8">
          <label className="block text-sm text-gray-400 mb-2">{t('customDuration')}</label>
          <input
            type="number"
            value={duration}
            onChange={(e) => setDuration(Math.max(1, parseInt(e.target.value) || 1))}
            className="w-full bg-gray-900 border border-gray-800 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-purple-600"
            placeholder={t('minutes')}
          />
        </div>

        <div className="bg-red-950 border border-red-900 rounded-xl p-4 mb-8">
          <div className="flex items-start gap-3">
            <AlertTriangle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
            <div>
              <div className="font-semibold text-red-400 mb-1">{t('warning')}</div>
              <div className="text-sm text-gray-400">
                {t('earlyExitWarning')}
              </div>
            </div>
          </div>
        </div>

        <div className="text-center mb-6">
          <div className="text-sm text-gray-500 mb-2">{t('currentStreak')}</div>
          <div className="flex items-center justify-center gap-2">
            <span className="text-4xl">🔥</span>
            <span className="text-4xl font-bold">{streak?.current_streak || 0}</span>
          </div>
        </div>

        <Button
          onClick={() => startMutation.mutate(duration)}
          disabled={startMutation.isPending}
          className="w-full bg-purple-600 hover:bg-purple-700 h-12 text-base font-semibold"
        >
          {startMutation.isPending ? t('starting') : t('beginFocusMode')}
        </Button>
      </div>
    </div>
  );
}