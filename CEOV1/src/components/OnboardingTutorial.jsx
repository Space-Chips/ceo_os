import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, ChevronRight, Sparkles, Target, Calendar, TrendingUp, Zap } from 'lucide-react';
import { Button } from '@/components/ui/button';

const tutorialSteps = [
  {
    icon: Sparkles,
    title: 'Welcome to CEO App',
    description: 'Your personal productivity command center. Swipe to learn the features.',
    color: 'from-purple-500 to-pink-500'
  },
  {
    icon: Target,
    title: 'Dashboard',
    description: 'Track your habits, validate yesterday\'s progress, and see your top priority tasks all in one place.',
    color: 'from-blue-500 to-cyan-500',
    customIcon: (
      <svg className="w-16 h-16" viewBox="0 0 24 24" fill="none">
        <path d="M3 3v18h18" 
              stroke="#6366f1" strokeWidth="1.8" 
              strokeLinecap="round" strokeLinejoin="round"/>
        <rect x="6.5" y="13" width="2.5" height="4" rx="0.5"
              fill="#6366f1" opacity="0.85"/>
        <rect x="10.5" y="9" width="2.5" height="8" rx="0.5"
              fill="#6366f1" opacity="0.9"/>
        <rect x="14.5" y="7" width="2.5" height="10" rx="0.5"
              fill="#6366f1" opacity="0.95"/>
      </svg>
    )
  },
  {
    icon: TrendingUp,
    title: 'To-Do Matrix',
    description: 'Prioritize tasks by importance and time. Focus on what truly moves the needle.',
    color: 'from-indigo-500 to-purple-500',
    customIcon: (
      <svg className="w-16 h-16" viewBox="0 0 24 24" fill="none">
        <path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" 
              stroke="#6366f1" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
        <path d="M9 14l2 2 4-4" 
              stroke="#6366f1" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    )
  },
  {
    icon: Calendar,
    title: 'Habits & Goals',
    description: 'Build lasting habits with weekly contracts, rewards, and accountability.',
    color: 'from-emerald-500 to-teal-500',
    customIcon: (
      <svg className="w-16 h-16" viewBox="0 0 24 24" fill="none">
        <circle cx="12" cy="12" r="9.5" stroke="#6366f1" strokeWidth="1.6"/>
        <path d="M7.5 12.5l3 3L17 9" 
              stroke="#6366f1" strokeWidth="2.4" 
              strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    )
  },
  {
    icon: Zap,
    title: 'Focus Mode',
    description: 'Activate distraction-free sessions to get deep work done. Build your win streak.',
    color: 'from-orange-500 to-red-500',
    customIcon: (
      <svg className="w-16 h-16" viewBox="0 0 24 24" fill="none">
        <path d="M12 2.5L4.5 6.5v5.5c0 5.2 3.6 10.1 7.5 11.5 3.9-1.4 7.5-6.3 7.5-11.5V6.5L12 2.5z" 
              stroke="#6366f1" strokeWidth="1.9" strokeLinejoin="round"/>
        <circle cx="12" cy="12.5" r="3.2" 
                stroke="#6366f1" strokeWidth="1.7"/>
        <path d="M12 9.5v3.5l2.2 2.2" 
              stroke="#6366f1" strokeWidth="2" strokeLinecap="round"/>
      </svg>
    )
  }
];

export default function OnboardingTutorial({ onComplete }) {
  const [currentStep, setCurrentStep] = useState(0);
  const [direction, setDirection] = useState(1);

  const handleNext = () => {
    if (currentStep === tutorialSteps.length - 1) {
      onComplete();
    } else {
      setDirection(1);
      setCurrentStep(prev => prev + 1);
    }
  };

  const handlePrev = () => {
    if (currentStep > 0) {
      setDirection(-1);
      setCurrentStep(prev => prev - 1);
    }
  };

  const handleSkip = () => {
    onComplete();
  };

  const step = tutorialSteps[currentStep];
  const Icon = step.icon;

  return (
    <div className="fixed inset-0 z-[9999] bg-black/95 backdrop-blur-xl flex items-center justify-center p-6">
      <button
        onClick={handleSkip}
        className="absolute top-6 right-6 p-2 rounded-full bg-zinc-900 hover:bg-zinc-800 transition-colors"
      >
        <X className="w-5 h-5 text-zinc-400" />
      </button>

      <div className="max-w-md w-full">
        <AnimatePresence mode="wait" custom={direction}>
          <motion.div
            key={currentStep}
            custom={direction}
            initial={{ opacity: 0, x: direction * 100 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: direction * -100 }}
            transition={{ duration: 0.3 }}
            className="space-y-8"
          >
            {/* Icon */}
            <div className="flex justify-center">
              <div className="relative w-32 h-32">
                {/* Blue accent glow */}
                <div className="absolute inset-0 rounded-3xl blur-xl opacity-40" 
                     style={{
                       background: 'linear-gradient(to bottom right, rgba(99, 102, 241, 0.4), rgba(139, 92, 246, 0.3))'
                     }}
                />
                {/* Matte dark container */}
                <div className="absolute inset-0 rounded-3xl"
                     style={{
                       background: '#2e2e2e',
                       boxShadow: `
                         0 4px 12px rgba(0, 0, 0, 0.4),
                         inset 0 1px 1px rgba(255, 255, 255, 0.03),
                         inset 0 -1px 1px rgba(0, 0, 0, 0.15)
                       `
                     }}
                />
                {/* Icon symbol */}
                <div className="absolute inset-0 flex items-center justify-center">
                  {step.customIcon || <Icon className="w-16 h-16" style={{ color: '#9a9a9a' }} />}
                </div>
              </div>
            </div>

            {/* Content */}
            <div className="text-center space-y-4">
              <h2 className="text-3xl font-bold text-white">{step.title}</h2>
              <p className="text-lg text-zinc-400 leading-relaxed">{step.description}</p>
            </div>

            {/* Progress dots */}
            <div className="flex justify-center gap-2">
              {tutorialSteps.map((_, index) => (
                <button
                  key={index}
                  onClick={() => {
                    setDirection(index > currentStep ? 1 : -1);
                    setCurrentStep(index);
                  }}
                  className={`h-2 rounded-full transition-all ${
                    index === currentStep 
                      ? 'w-8 bg-white' 
                      : 'w-2 bg-zinc-700 hover:bg-zinc-600'
                  }`}
                />
              ))}
            </div>

            {/* Navigation */}
            <div className="flex gap-3">
              {currentStep > 0 && (
                <Button
                  onClick={handlePrev}
                  variant="outline"
                  className="flex-1 bg-zinc-900 border-zinc-800 hover:bg-zinc-800"
                >
                  Previous
                </Button>
              )}
              <Button
                onClick={handleNext}
                className="flex-1 bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white"
              >
                {currentStep === tutorialSteps.length - 1 ? 'Get Started' : 'Next'}
                {currentStep !== tutorialSteps.length - 1 && <ChevronRight className="w-4 h-4 ml-1" />}
              </Button>
            </div>
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}