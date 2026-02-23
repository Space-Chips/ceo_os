import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { ArrowLeft } from 'lucide-react';
import { useLanguage } from '../components/LanguageProvider';
import NormalModeBlockingScreen from '../components/blocking/NormalModeBlockingScreen';
import FocusModeBlockingScreen from '../components/blocking/FocusModeBlockingScreen';
import { Button } from '@/components/ui/button';

export default function BlockingDemo() {
  const { t } = useLanguage();
  const [showNormalBlock, setShowNormalBlock] = useState(false);
  const [showFocusBlock, setShowFocusBlock] = useState(false);

  return (
    <div className="min-h-screen bg-gradient-to-b from-zinc-950 via-black to-zinc-950 text-white p-6 pt-20 pb-12 relative overflow-hidden">
      <div className="fixed inset-0 pointer-events-none opacity-[0.015]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      <div className="max-w-2xl mx-auto relative">
        <div className="flex items-center justify-between mb-6">
          <Link to={createPageUrl('ScreenTimeManager')} className="inline-flex items-center gap-2 text-zinc-600 hover:text-zinc-300 transition-colors duration-150 active:scale-95">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-sm font-medium">{t('back')}</span>
          </Link>
          
          <h1 className="text-xl font-black bg-gradient-to-r from-white via-zinc-100 to-zinc-300 bg-clip-text text-transparent tracking-tight">
            {t('blockingPreview')}
          </h1>
          
          <div className="w-20" />
        </div>

        <div className="space-y-4">
          <div className="p-6 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
            <h2 className="text-base font-bold text-white mb-2">{t('normalModeBlocking')}</h2>
            <p className="text-xs text-zinc-500 mb-4">
              {t('whenBlockedAppAccessed')}
            </p>
            <Button
              onClick={() => setShowNormalBlock(true)}
              className="bg-white text-black hover:bg-zinc-200"
            >
              {t('previewNormalMode')}
            </Button>
          </div>

          <div className="p-6 rounded-xl bg-zinc-900/40 border border-zinc-800/40">
            <h2 className="text-base font-bold text-white mb-2">{t('focusModeBlocking')}</h2>
            <p className="text-xs text-zinc-500 mb-4">
              {t('duringFocusMode')}
            </p>
            <Button
              onClick={() => setShowFocusBlock(true)}
              className="bg-white text-black hover:bg-zinc-200"
            >
              {t('previewFocusMode')}
            </Button>
          </div>

          <div className="p-5 rounded-xl bg-blue-950/20 border border-blue-900/30">
            <p className="text-xs text-blue-300/80 leading-relaxed">
              <span className="font-bold">{t('note')}:</span> {t('productionNote')}
            </p>
          </div>
        </div>
      </div>

      {showNormalBlock && (
        <NormalModeBlockingScreen
          entityName="Instagram"
          timeSpentToday={45}
          onClose={() => setShowNormalBlock(false)}
        />
      )}

      {showFocusBlock && (
        <FocusModeBlockingScreen
          entityName="YouTube"
          currentStreak={12}
          onExitFocusMode={() => {
            setShowFocusBlock(false);
            alert('Focus Mode would be exited and streak reset');
          }}
          onClose={() => setShowFocusBlock(false)}
        />
      )}
    </div>
  );
}