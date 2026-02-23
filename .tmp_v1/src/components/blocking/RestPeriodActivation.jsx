import React, { useState, useEffect } from 'react';
import { Coffee, X } from 'lucide-react';
import { Button } from '@/components/ui/button';

export default function RestPeriodActivation({ restPeriod, onConfirm, onCancel }) {
  const [countdown, setCountdown] = useState(8);

  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => clearTimeout(timer);
    } else {
      onConfirm();
    }
  }, [countdown, onConfirm]);

  return (
    <div className="fixed inset-0 z-50 bg-black/95 backdrop-blur-xl flex items-center justify-center">
      {/* Noise texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.02]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      <div className="relative max-w-md w-full mx-4 text-center">
        {/* Breathing animation circle */}
        <div className="relative mb-8">
          <div 
            className="absolute inset-0 mx-auto w-48 h-48 rounded-full bg-gradient-to-br from-blue-500/30 to-cyan-500/30 blur-3xl"
            style={{
              animation: 'breathe 3s ease-in-out infinite'
            }}
          />
          <div className="relative w-48 h-48 mx-auto rounded-full bg-gradient-to-br from-blue-950/60 to-cyan-950/60 border-2 border-blue-500/30 flex items-center justify-center shadow-[0_0_80px_rgba(59,130,246,0.3)]">
            <div className="text-center">
              <div className="text-6xl font-black text-white mb-2">{countdown}</div>
              <Coffee className="w-8 h-8 text-blue-400 mx-auto" />
            </div>
          </div>
        </div>

        <h2 className="text-2xl font-black text-white mb-2">Activating Rest Period</h2>
        <p className="text-zinc-400 text-sm mb-1">
          All restrictions will be paused for {restPeriod.duration_minutes} minutes
        </p>
        <p className="text-zinc-600 text-xs mb-8">
          {restPeriod.reason}
        </p>

        {countdown > 0 && (
          <Button
            onClick={onCancel}
            variant="outline"
            className="border-zinc-700 hover:bg-zinc-800 text-white"
          >
            <X className="w-4 h-4 mr-2" />
            Cancel Break
          </Button>
        )}
      </div>

      <style jsx>{`
        @keyframes breathe {
          0%, 100% { transform: scale(1); opacity: 0.3; }
          50% { transform: scale(1.1); opacity: 0.5; }
        }
      `}</style>
    </div>
  );
}