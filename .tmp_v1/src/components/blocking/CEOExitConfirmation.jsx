import React, { useState } from 'react';
import { AlertTriangle } from 'lucide-react';
import { Button } from '@/components/ui/button';

export default function CEOExitConfirmation({ 
  onConfirm, 
  onCancel 
}) {
  const [firstConfirmed, setFirstConfirmed] = useState(false);

  if (!firstConfirmed) {
    return (
      <div className="fixed inset-0 bg-black z-[200] flex items-center justify-center p-6">
        <div className="max-w-md w-full">
          <div className="text-center mb-10">
            <div className="mb-6">
              <AlertTriangle className="w-16 h-16 mx-auto text-red-500" />
            </div>
            <h2 className="text-2xl font-black text-white mb-3 tracking-tight">
              Quitter le mode CEO ?
            </h2>
            <p className="text-sm text-zinc-400 mb-6 leading-relaxed">
              Quitter le mode CEO mettra fin à ta session et <span className="text-red-400 font-bold">annulera ta streak</span>.
            </p>
          </div>

          <div className="space-y-3">
            <Button
              onClick={() => setFirstConfirmed(true)}
              className="w-full bg-red-600 hover:bg-red-500 text-white h-12 font-bold rounded-xl active:scale-[0.98] transition-all"
            >
              Continuer la sortie
            </Button>
            <Button
              onClick={onCancel}
              className="w-full bg-white text-black hover:bg-zinc-200 h-12 font-bold rounded-xl active:scale-[0.98] transition-all"
            >
              Rester en mode CEO
            </Button>
          </div>
        </div>
      </div>
    );
  }

  // Deuxième confirmation
  return (
    <div className="fixed inset-0 bg-black z-[200] flex items-center justify-center p-6">
      <div className="max-w-md w-full">
        <div className="text-center mb-10">
          <div className="mb-6">
            <div className="w-16 h-16 mx-auto rounded-full bg-red-950/60 border-2 border-red-500/50 flex items-center justify-center">
              <span className="text-3xl">⚠️</span>
            </div>
          </div>
          <h2 className="text-2xl font-black text-white mb-3 tracking-tight">
            Dernière confirmation
          </h2>
          <p className="text-sm text-zinc-400 mb-6 leading-relaxed">
            Es-tu vraiment sûr de vouloir quitter ? Cette action est <span className="text-red-400 font-bold">irréversible</span>.
          </p>
        </div>

        <div className="space-y-3">
          <Button
            onClick={onConfirm}
            className="w-full bg-red-600 hover:bg-red-500 text-white h-12 font-bold rounded-xl active:scale-[0.98] transition-all"
          >
            Oui, quitter définitivement
          </Button>
          <Button
            onClick={onCancel}
            className="w-full bg-white text-black hover:bg-zinc-200 h-12 font-bold rounded-xl active:scale-[0.98] transition-all"
          >
            Annuler
          </Button>
        </div>
      </div>
    </div>
  );
}