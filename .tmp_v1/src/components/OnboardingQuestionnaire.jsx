import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronRight, Briefcase, Heart, Dumbbell, BookOpen, ShoppingBag, Users, Loader2, Sparkles } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { base44 } from '@/api/base44Client';

export default function OnboardingQuestionnaire({ onComplete }) {
  const [step, setStep] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    mainGoals: '',
    habitCategories: [],
    workType: '',
    challenges: '',
    idealDay: ''
  });

  const categories = [
    { id: 'work', label: 'Work & Career', icon: Briefcase },
    { id: 'health', label: 'Health & Wellness', icon: Heart },
    { id: 'fitness', label: 'Fitness & Sports', icon: Dumbbell },
    { id: 'learning', label: 'Learning & Growth', icon: BookOpen },
    { id: 'personal', label: 'Personal Projects', icon: ShoppingBag },
    { id: 'social', label: 'Social & Family', icon: Users }
  ];

  const workOptions = [
    'Entrepreneur',
    'Student',
    'Engineer / Developer',
    'Manager / Executive',
    'Designer / Creative',
    'Healthcare Professional',
    'Sales / Marketing',
    'Freelancer',
    'Other'
  ];

  const challengeOptions = [
    'Staying focused',
    'Managing time effectively',
    'Building consistency',
    'Avoiding procrastination',
    'Balancing work and life',
    'Setting clear goals',
    'Other'
  ];

  const goalOptions = [
    'Launch my business',
    'Get fit and healthy',
    'Learn a new language',
    'Advance my career',
    'Build better habits',
    'Improve productivity',
    'Reduce screen time',
    'Other'
  ];

  const toggleCategory = (id) => {
    setFormData(prev => ({
      ...prev,
      habitCategories: prev.habitCategories.includes(id)
        ? prev.habitCategories.filter(c => c !== id)
        : [...prev.habitCategories, id]
    }));
  };

  const handleComplete = async () => {
    setIsLoading(true);
    
    // Smart loading animation (2 seconds)
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    try {
      const user = await base44.auth.me();
      await base44.auth.updateMe({
        onboarding_data: formData
      });
    } catch (error) {
      console.error('Error saving onboarding data:', error);
    }
    
    onComplete();
  };

  if (isLoading) {
    return (
      <div className="fixed inset-0 z-[9999] bg-black flex flex-col items-center justify-center p-6">
        <motion.div
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ duration: 0.5 }}
          className="text-center"
        >
          {/* Indicateur de chargement moderne et sobre */}
          <div className="w-20 h-20 mx-auto mb-6 relative flex items-center justify-center">
            {/* Cercle animé extérieur */}
            <motion.div
              className="absolute inset-0"
              animate={{ rotate: 360 }}
              transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
            >
              <svg className="w-full h-full" viewBox="0 0 80 80">
                <circle
                  cx="40"
                  cy="40"
                  r="36"
                  fill="none"
                  stroke="url(#gradient)"
                  strokeWidth="3"
                  strokeLinecap="round"
                  strokeDasharray="180 40"
                />
                <defs>
                  <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#3b82f6" stopOpacity="0.9" />
                    <stop offset="100%" stopColor="#6366f1" stopOpacity="0.4" />
                  </linearGradient>
                </defs>
              </svg>
            </motion.div>
            
            {/* Point central pulsant */}
            <motion.div
              animate={{ scale: [1, 1.2, 1], opacity: [0.6, 1, 0.6] }}
              transition={{ duration: 2, repeat: Infinity }}
              className="w-3 h-3 rounded-full bg-blue-400 shadow-[0_0_16px_rgba(96,165,250,0.8)]"
            />
          </div>
          
          <motion.h2
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.3 }}
            className="text-2xl font-bold text-white mb-2"
          >
            Analyzing your profile...
          </motion.h2>
          
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.5 }}
            className="flex items-center justify-center gap-2"
          >
            <Loader2 className="w-4 h-4 text-zinc-400 animate-spin" />
            <p className="text-zinc-400">Creating your personalized experience</p>
          </motion.div>
        </motion.div>
      </div>
    );
  }

  const steps = [
    {
      title: "What are your main goals?",
      description: "Select all that apply or write your own",
      content: (
        <div className="space-y-3">
          <div className="grid grid-cols-2 gap-2">
            {goalOptions.slice(0, -1).map(goal => {
              const isSelected = formData.mainGoals.includes(goal);
              return (
                <button
                  key={goal}
                  onClick={() => {
                    setFormData(prev => ({
                      ...prev,
                      mainGoals: isSelected 
                        ? prev.mainGoals.replace(goal, '').replace(/,\s*,/g, ',').replace(/^,\s*/, '').replace(/,\s*$/, '')
                        : prev.mainGoals ? `${prev.mainGoals}, ${goal}` : goal
                    }));
                  }}
                  className={`p-3 rounded-xl border-2 transition-all text-sm font-medium ${
                    isSelected
                      ? 'bg-white text-black border-white'
                      : 'bg-zinc-900 border-zinc-800 text-white hover:border-zinc-700'
                  }`}
                >
                  {goal}
                </button>
              );
            })}
          </div>
          <Textarea
            value={formData.mainGoals}
            onChange={(e) => setFormData({ ...formData, mainGoals: e.target.value })}
            placeholder="Or type your own goals..."
            className="bg-zinc-900 border-zinc-800 text-white h-20 resize-none"
          />
        </div>
      )
    },
    {
      title: "Which areas matter most?",
      description: "Select the categories you want to focus on",
      content: (
        <div className="grid grid-cols-2 gap-3">
          {categories.map(cat => {
            const Icon = cat.icon;
            const isSelected = formData.habitCategories.includes(cat.id);
            return (
              <button
                key={cat.id}
                onClick={() => toggleCategory(cat.id)}
                className={`p-4 rounded-xl border-2 transition-all ${
                  isSelected
                    ? 'bg-white text-black border-white'
                    : 'bg-zinc-900 border-zinc-800 text-white hover:border-zinc-700'
                }`}
              >
                <Icon className={`w-6 h-6 mx-auto mb-2 ${isSelected ? 'text-black' : 'text-blue-500'}`} />
                <div className="text-sm font-medium">{cat.label}</div>
              </button>
            );
          })}
        </div>
      )
    },
    {
      title: "What do you do professionally?",
      description: "This helps us suggest relevant tasks and habits",
      content: (
        <div className="grid grid-cols-2 gap-2">
          {workOptions.map(work => {
            const isSelected = formData.workType === work;
            return (
              <button
                key={work}
                onClick={() => setFormData({ ...formData, workType: work })}
                className={`p-3 rounded-xl border-2 transition-all text-sm font-medium ${
                  isSelected
                    ? 'bg-white text-black border-white'
                    : 'bg-zinc-900 border-zinc-800 text-white hover:border-zinc-700'
                }`}
              >
                {work}
              </button>
            );
          })}
        </div>
      )
    },
    {
      title: "What's your biggest challenge?",
      description: "Select all that apply",
      content: (
        <div className="grid grid-cols-2 gap-2">
          {challengeOptions.map(challenge => {
            const isSelected = formData.challenges.includes(challenge);
            return (
              <button
                key={challenge}
                onClick={() => {
                  setFormData(prev => ({
                    ...prev,
                    challenges: isSelected 
                      ? prev.challenges.replace(challenge, '').replace(/,\s*,/g, ',').replace(/^,\s*/, '').replace(/,\s*$/, '')
                      : prev.challenges ? `${prev.challenges}, ${challenge}` : challenge
                  }));
                }}
                className={`p-3 rounded-xl border-2 transition-all text-sm font-medium ${
                  isSelected
                    ? 'bg-white text-black border-white'
                    : 'bg-zinc-900 border-zinc-800 text-white hover:border-zinc-700'
                }`}
              >
                {challenge}
              </button>
            );
          })}
        </div>
      )
    }
  ];

  const currentStep = steps[step];

  return (
    <div className="fixed inset-0 z-[9999] bg-black flex items-center justify-center p-6">
      <div className="max-w-lg w-full">
        <AnimatePresence mode="wait">
          <motion.div
            key={step}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
            className="space-y-8"
          >
            {/* Progress */}
            <div className="flex gap-2">
              {steps.map((_, index) => (
                <div
                  key={index}
                  className={`h-1 rounded-full flex-1 transition-all ${
                    index <= step ? 'bg-white' : 'bg-zinc-800'
                  }`}
                />
              ))}
            </div>

            {/* Content */}
            <div className="space-y-4">
              <div>
                <h2 className="text-2xl font-bold text-white mb-2">{currentStep.title}</h2>
                <p className="text-zinc-400">{currentStep.description}</p>
              </div>
              {currentStep.content}
            </div>

            {/* Navigation */}
            <div className="flex gap-3">
              {step > 0 && (
                <Button
                  onClick={() => setStep(step - 1)}
                  variant="outline"
                  className="flex-1 bg-zinc-900 border-zinc-800 hover:bg-zinc-800"
                >
                  Back
                </Button>
              )}
              <Button
                onClick={() => {
                  if (step === steps.length - 1) {
                    handleComplete();
                  } else {
                    setStep(step + 1);
                  }
                }}
                className="flex-1 bg-white text-black hover:bg-zinc-200"
              >
                {step === steps.length - 1 ? 'Complete' : 'Next'}
                {step !== steps.length - 1 && <ChevronRight className="w-4 h-4 ml-1" />}
              </Button>
            </div>

            {/* Skip option */}
            {step === 0 && (
              <button
                onClick={onComplete}
                className="w-full text-center text-sm text-zinc-600 hover:text-zinc-400 transition-colors"
              >
                Skip for now
              </button>
            )}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}