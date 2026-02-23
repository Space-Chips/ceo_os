import React from 'react';
import { useNavigate } from 'react-router-dom';
import { createPageUrl } from '../../utils';
import { useLanguage } from '../LanguageProvider';
import { useQuery } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { X } from 'lucide-react';

export default function NormalModeBlockingScreen({ 
  entityName, 
  timeSpentToday = 0, 
  onClose 
}) {
  const { t } = useLanguage();
  const navigate = useNavigate();

  const handleGoToPriorities = () => {
    navigate(createPageUrl('Dashboard'));
    if (onClose) onClose();
  };

  const handleComeLater = () => {
    if (onClose) onClose();
  };

  const { data: objectives } = useQuery({
    queryKey: ['objectives'],
    queryFn: async () => {
      const user = await base44.auth.me();
      return await base44.entities.Objective.filter({ created_by: user.email, archived: false });
    },
    initialData: []
  });

  return (
    <div className="fixed inset-0 bg-black z-[100] flex items-center justify-center p-6 overflow-hidden">
      {/* Noise texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.02]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='2.5' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '128px 128px'
      }} />

      {/* Ambient gradient */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[800px] bg-gradient-to-b from-blue-500/5 via-purple-500/5 to-transparent rounded-full blur-[120px] pointer-events-none" />

      <div className="relative max-w-md w-full">
        {/* Visual Content - User Objectives */}
        <div className="mb-8 relative">
          <div className="absolute inset-0 bg-gradient-to-b from-blue-500/10 to-purple-500/10 rounded-[32px] blur-2xl" />
          <div className="relative aspect-[4/3] rounded-[32px] bg-gradient-to-br from-zinc-900/80 to-zinc-950/80 border border-zinc-800/50 overflow-hidden shadow-[0_20px_80px_rgba(0,0,0,0.6)] p-6 flex flex-col justify-center">
            <div className="absolute inset-0 bg-gradient-to-t from-black via-black/70 to-transparent" />
            <div className="relative space-y-3 opacity-70">
              {objectives && objectives.length > 0 ? (
                objectives.slice(0, 3).map(obj => (
                  <div key={obj.id} className="flex items-center gap-3 p-3 rounded-xl bg-zinc-900/60 border border-zinc-800/50">
                    <span className="text-2xl">{obj.icon}</span>
                    <span className="text-sm font-bold text-white">{obj.title}</span>
                  </div>
                ))
              ) : (
                <div className="text-center text-zinc-600 text-sm">Your objectives will appear here</div>
              )}
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="text-center mb-10">
          <h1 className="text-3xl font-black mb-3 bg-gradient-to-r from-white via-zinc-100 to-zinc-300 bg-clip-text text-transparent tracking-tight">
            {t('language') === 'fr' ? "Vous scrollez par réflexe." : 
             t('language') === 'es' ? "Estás desplazándote por inercia." :
             t('language') === 'zh' ? "你在自动滚动。" :
             t('language') === 'hi' ? "आप ऑटोपायलट पर स्क्रॉल कर रहे हैं।" :
             t('language') === 'id' ? "Anda menggulir secara otomatis." :
             t('language') === 'ru' ? "Вы скроллите на автопилоте." :
             t('language') === 'pt' ? "Você está rolando no piloto automático." :
             t('language') === 'ar' ? "أنت تتصفح على الطيار الآلي." :
             "You're scrolling on autopilot."}
          </h1>
          <p className="text-base text-zinc-400 mb-6 font-medium">
            {t('language') === 'fr' ? "N'avez-vous pas quelque chose de plus important à faire ? Vous connaissez déjà la réponse." :
             t('language') === 'es' ? "¿No tienes algo más importante que hacer? Ya sabes la respuesta." :
             t('language') === 'zh' ? "你不是有更重要的事情要做吗？你已经知道答案了。" :
             t('language') === 'hi' ? "क्या आपके पास कुछ अधिक महत्वपूर्ण करने के लिए नहीं है? आप पहले से ही जवाब जानते हैं।" :
             t('language') === 'id' ? "Tidakkah Anda memiliki sesuatu yang lebih penting untuk dilakukan? Anda sudah tahu jawabannya." :
             t('language') === 'ru' ? "Разве у вас нет чего-то более важного? Вы уже знаете ответ." :
             t('language') === 'pt' ? "Você não tem algo mais importante para fazer? Você já sabe a resposta." :
             t('language') === 'ar' ? "ألا يوجد لديك شيء أكثر أهمية لفعله؟ أنت تعرف الإجابة بالفعل." :
             "Don't you have something more important to do? You already know the answer."}
          </p>
          
          {/* Awareness line */}
          <div className="relative">
            <div className="absolute inset-0 bg-orange-500/10 rounded-2xl blur-xl" />
            <div className="relative px-5 py-3 rounded-2xl bg-zinc-900/60 border border-orange-500/30">
              <p className="text-sm text-orange-300/90">
                You've already spent <span className="font-black">{timeSpentToday} minutes</span> on {entityName} today.
              </p>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="space-y-3">
          {/* Primary - Go to priorities */}
          <button
            onClick={handleGoToPriorities}
            className="w-full relative group"
          >
            <div className="absolute inset-0 bg-gradient-to-r from-blue-500/30 to-purple-500/30 rounded-2xl blur-xl group-hover:blur-2xl transition-all duration-300" />
            <div className="relative py-5 rounded-2xl bg-gradient-to-br from-white via-zinc-100 to-white text-black font-black text-base tracking-tight shadow-[0_12px_48px_rgba(255,255,255,0.15)] hover:shadow-[0_16px_64px_rgba(255,255,255,0.25)] active:scale-[0.97] transition-all duration-150">
              → Open my to-do list
            </div>
          </button>

          {/* Secondary - Close */}
          <button
            onClick={handleComeLater}
            className="w-full py-4 rounded-2xl bg-zinc-900/40 border border-zinc-800/50 text-zinc-400 hover:bg-zinc-900/60 hover:text-zinc-300 font-semibold text-sm active:scale-[0.98] transition-all duration-150"
          >
            I'll come back later
          </button>
        </div>

        {/* Subtle hint */}
        <p className="text-center text-xs text-zinc-700 mt-6 font-medium">
          To add time, open the app and go to Screen Time settings
        </p>
      </div>
    </div>
  );
}