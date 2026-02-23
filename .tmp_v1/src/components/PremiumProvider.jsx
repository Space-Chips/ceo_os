import React, { createContext, useContext } from 'react';
import { useQuery } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';

const PremiumContext = createContext();

export function PremiumProvider({ children }) {
  // Vérifier le statut d'abonnement Stripe
  const { data: subscriptionStatus } = useQuery({
    queryKey: ['subscriptionStatus'],
    queryFn: async () => {
      try {
        const user = await base44.auth.me();
        if (!user) return { isPremium: false, status: 'none' };
        
        // Vérifier si Stripe est configuré
        const stripeStatus = await base44.stripe?.getSubscriptionStatus?.();
        return {
          isPremium: stripeStatus?.status === 'active' || stripeStatus?.status === 'trialing',
          status: stripeStatus?.status || 'none'
        };
      } catch (error) {
        // Stripe non configuré ou erreur
        return { isPremium: false, status: 'none' };
      }
    },
    initialData: { isPremium: false, status: 'none' }
  });

  // Vérifier le mode de lancement gratuit
  const { data: appConfig } = useQuery({
    queryKey: ['appConfig'],
    queryFn: async () => {
      const configs = await base44.entities.AppConfig.list();
      if (configs.length === 0) {
        // Créer la config par défaut avec freeLaunchMode = true
        const newConfig = await base44.entities.AppConfig.create({
          config_name: 'global',
          free_launch_mode: true
        });
        return newConfig;
      }
      return configs[0];
    },
    initialData: { free_launch_mode: true }
  });

  const freeLaunchMode = appConfig?.free_launch_mode ?? true;
  const isPremiumUser = freeLaunchMode || subscriptionStatus.isPremium;

  return (
    <PremiumContext.Provider value={{ 
      isPremiumUser, 
      freeLaunchMode,
      subscriptionStatus: subscriptionStatus.status 
    }}>
      {children}
    </PremiumContext.Provider>
  );
}

export function usePremium() {
  const context = useContext(PremiumContext);
  if (!context) {
    throw new Error('usePremium must be used within PremiumProvider');
  }
  return context;
}