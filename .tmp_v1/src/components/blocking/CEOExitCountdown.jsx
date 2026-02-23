import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { createPageUrl } from '../../utils';

export default function CEOExitCountdown({ 
  onComplete, 
  onCancel 
}) {
  const navigate = useNavigate();
  const [countdown, setCountdown] = useState(10);
  const [isVisible, setIsVisible] = useState(true);
  const countdownIntervalRef = useRef(null);

  // Fonction pour démarrer/redémarrer le compte à rebours
  const startCountdown = () => {
    setCountdown(10);
    
    if (countdownIntervalRef.current) {
      clearInterval(countdownIntervalRef.current);
    }
    
    countdownIntervalRef.current = setInterval(() => {
      setCountdown(prev => {
        if (prev <= 1) {
          clearInterval(countdownIntervalRef.current);
          if (onComplete) onComplete();
          return 0;
        }
        return prev - 1;
      });
    }, 60000); // 1 minute = 60000ms
  };

  // Démarrer au montage
  useEffect(() => {
    startCountdown();
    
    return () => {
      if (countdownIntervalRef.current) {
        clearInterval(countdownIntervalRef.current);
      }
    };
  }, []);

  // Détection de visibilité - réinitialise si l'utilisateur quitte
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden) {
        setIsVisible(false);
      } else {
        if (!isVisible) {
          // L'utilisateur revient après avoir quitté - réinitialiser
          startCountdown();
        }
        setIsVisible(true);
      }
    };

    const handleBlur = () => {
      setIsVisible(false);
    };

    const handleFocus = () => {
      if (!isVisible) {
        startCountdown();
      }
      setIsVisible(true);
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('blur', handleBlur);
    window.addEventListener('focus', handleFocus);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('blur', handleBlur);
      window.removeEventListener('focus', handleFocus);
    };
  }, [isVisible]);

  return (
    <div className="fixed inset-0 bg-black z-[200] flex flex-col items-center justify-center p-6">
      {/* Compte à rebours */}
      <div className="mb-16">
        <div className="text-[180px] font-black text-white leading-none tracking-tighter tabular-nums">
          {countdown}
        </div>
      </div>

      {/* Message subtil en bas */}
      <div className="absolute bottom-12 left-0 right-0 px-6">
        <div className="max-w-md mx-auto space-y-4">
          <p className="text-center text-xs text-zinc-700 font-medium">
            Reste sur cet écran. Si tu quittes, le compteur redémarre à 10.
          </p>
          
          <button
            onClick={onCancel}
            className="w-full py-3 rounded-xl bg-zinc-900/40 border border-zinc-800/50 text-zinc-500 hover:text-zinc-300 hover:bg-zinc-900/60 text-sm font-semibold active:scale-[0.98] transition-all"
          >
            Annuler et retourner au mode CEO
          </button>
        </div>
      </div>
    </div>
  );
}