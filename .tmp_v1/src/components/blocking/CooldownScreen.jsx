import React, { useState, useEffect } from 'react';
import { useLanguage } from '../LanguageProvider';

export default function CooldownScreen({ 
  onComplete, 
  onCancel,
  message = "Take a breath"
}) {
  const { t } = useLanguage();
  const [countdown, setCountdown] = useState(8);

  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => {
        setCountdown(countdown - 1);
      }, 1000);
      return () => clearTimeout(timer);
    } else {
      // Countdown complete
      if (onComplete) onComplete();
    }
  }, [countdown, onComplete]);

  return (
    <div className="fixed inset-0 bg-black/95 backdrop-blur-xl z-[110] flex items-center justify-center p-6">
      {/* Noise texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.02]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      <div className="relative text-center">
        {/* Breathing circle animation */}
        <div className="relative mb-12">
          <div 
            className="absolute inset-0 bg-white/5 rounded-full blur-[60px] animate-pulse" 
            style={{ animationDuration: '4s' }}
          />
          <div 
            className="relative w-32 h-32 mx-auto rounded-full border-2 border-zinc-800 flex items-center justify-center"
            style={{
              animation: 'breathe 4s ease-in-out infinite'
            }}
          >
            <div className="text-6xl font-black text-white tabular-nums">
              {countdown}
            </div>
          </div>
        </div>

        <h2 className="text-2xl font-black text-white mb-3 tracking-tight">
          {message}
        </h2>
        <p className="text-sm text-zinc-500 mb-10 font-medium">
          {countdown > 0 ? 'Just a moment to reconsider...' : 'Ready to proceed'}
        </p>

        {/* Cancel button - available during countdown */}
        {countdown > 0 && (
          <button
            onClick={onCancel}
            className="px-8 py-4 rounded-2xl bg-zinc-900/60 border border-zinc-800/60 text-white hover:bg-zinc-900/80 hover:border-zinc-700/60 font-bold text-sm active:scale-95 transition-all duration-150 shadow-[0_8px_32px_rgba(0,0,0,0.5)]"
          >
            Cancel — stay focused
          </button>
        )}
      </div>

      <style>{`
        @keyframes breathe {
          0%, 100% { transform: scale(1); }
          50% { transform: scale(1.1); }
        }
      `}</style>
    </div>
  );
}