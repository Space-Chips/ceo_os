import React from 'react';
import { useNavigate } from 'react-router-dom';
import { createPageUrl } from '../../utils';
import { useLanguage } from '../LanguageProvider';
import { AlertTriangle } from 'lucide-react';

export default function FocusModeBlockingScreen({ 
  entityName,
  currentStreak = 0,
  onExitFocusMode,
  onClose 
}) {
  const { t } = useLanguage();
  const navigate = useNavigate();

  const handleReturnToFocus = () => {
    if (onClose) onClose();
  };

  const handleExitFocusMode = () => {
    if (onExitFocusMode) onExitFocusMode();
  };

  return (
    <div className="fixed inset-0 bg-black z-[100] flex items-center justify-center p-6 overflow-hidden">
      {/* Noise texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.015]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      {/* Minimal ambient */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-gradient-to-b from-red-500/3 to-transparent rounded-full blur-[120px] pointer-events-none" />

      <div className="relative max-w-md w-full">
        {/* Visual Content - Pure Black */}
        <div className="mb-8 relative">
          <div className="relative aspect-[4/3] rounded-[32px] bg-black border-2 border-zinc-900/80 overflow-hidden shadow-[0_20px_80px_rgba(0,0,0,0.9)]">
            <div className="absolute inset-0 bg-gradient-to-t from-black via-black/90 to-zinc-950/20" />
          </div>
        </div>

        {/* Content */}
        <div className="text-center mb-10">
          <h1 className="text-3xl font-black mb-3 text-white tracking-tight">
            {t('language') === 'fr' ? "Vous êtes en Mode Focus." :
             t('language') === 'es' ? "Estás en Modo Enfoque." :
             t('language') === 'zh' ? "您处于专注模式。" :
             t('language') === 'hi' ? "आप फोकस मोड में हैं।" :
             t('language') === 'id' ? "Anda dalam Mode Fokus." :
             t('language') === 'ru' ? "Вы в режиме фокуса." :
             t('language') === 'pt' ? "Você está no Modo Foco." :
             t('language') === 'ar' ? "أنت في وضع التركيز." :
             "You're in Focus Mode."}
          </h1>
          <p className="text-base text-zinc-500 mb-6 font-medium">
            {t('language') === 'fr' ? "Souviens-toi pourquoi tu as commencé cette session." :
             t('language') === 'es' ? "Recuerda por qué comenzaste esta sesión." :
             t('language') === 'zh' ? "记住你为什么开始这个会话。" :
             t('language') === 'hi' ? "याद रखें कि आपने यह सत्र क्यों शुरू किया।" :
             t('language') === 'id' ? "Ingat mengapa Anda memulai sesi ini." :
             t('language') === 'ru' ? "Вспомните, зачем вы начали эту сессию." :
             t('language') === 'pt' ? "Lembre-se por que você começou esta sessão." :
             t('language') === 'ar' ? "تذكر لماذا بدأت هذه الجلسة." :
             "Remember why you started this session."}
          </p>
          
          {/* Warning box */}
          <div className="relative mb-6">
            <div className="absolute inset-0 bg-red-500/20 rounded-2xl blur-xl" />
            <div className="relative px-5 py-4 rounded-2xl bg-red-950/40 border-2 border-red-900/50">
              <div className="flex items-start gap-3 text-left">
                <AlertTriangle className="w-5 h-5 text-red-400 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-sm text-red-300 font-bold mb-1">
                    Exiting Focus Mode will reset your win streak.
                  </p>
                  <p className="text-xs text-red-400/70">
                    Current streak: <span className="font-black">{currentStreak} days</span>
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="space-y-3">
          {/* Primary - Return to focus */}
          <button
            onClick={handleReturnToFocus}
            className="w-full relative group"
          >
            <div className="absolute inset-0 bg-gradient-to-r from-white/10 to-white/5 rounded-2xl blur-xl transition-all duration-300" />
            <div className="relative py-5 rounded-2xl bg-white text-black font-black text-base tracking-tight shadow-[0_12px_48px_rgba(255,255,255,0.15)] hover:shadow-[0_16px_64px_rgba(255,255,255,0.25)] active:scale-[0.97] transition-all duration-150">
              Return to focus
            </div>
          </button>

          {/* Secondary - Exit (destructive) */}
          <button
            onClick={handleExitFocusMode}
            className="w-full py-3 rounded-2xl bg-transparent border border-red-900/50 text-red-500 hover:bg-red-950/30 hover:border-red-900/70 font-semibold text-sm active:scale-[0.98] transition-all duration-150"
          >
            Exit Focus Mode
          </button>
        </div>
      </div>
    </div>
  );
}