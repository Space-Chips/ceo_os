import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getCurrentWeekContract, createWeeklyContract, commitToContract, calculateWeeklyHabitScore } from '../functions/businessLogic';
import { base44 } from '@/api/base44Client';
import { format, startOfWeek, addDays } from 'date-fns';
import { ArrowLeft, Gift, AlertTriangle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Slider } from '@/components/ui/slider';

export default function Rewards() {
  const queryClient = useQueryClient();
  const [rewardText, setRewardText] = useState('');
  const [sanctionText, setSanctionText] = useState('');
  const [threshold, setThreshold] = useState(90);

  const weekStart = startOfWeek(new Date(), { weekStartsOn: 1 });

  const { data: contract } = useQuery({
    queryKey: ['currentContract'],
    queryFn: getCurrentWeekContract
  });

  const { data: weeklyScore } = useQuery({
    queryKey: ['weeklyScore', format(weekStart, 'yyyy-MM-dd')],
    queryFn: () => calculateWeeklyHabitScore(weekStart),
    enabled: !!contract && contract.committed
  });

  const createMutation = useMutation({
    mutationFn: () => createWeeklyContract(rewardText, sanctionText, threshold),
    onSuccess: () => {
      queryClient.invalidateQueries(['currentContract']);
      setRewardText('');
      setSanctionText('');
    }
  });

  const commitMutation = useMutation({
    mutationFn: (contractId) => commitToContract(contractId),
    onSuccess: () => {
      queryClient.invalidateQueries(['currentContract']);
    }
  });

  const daysRemaining = 7 - new Date().getDay();

  // No contract state
  if (!contract) {
    return (
      <div className="min-h-screen bg-black text-white p-6">
        <div className="max-w-md mx-auto">
          <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-gray-400 mb-8">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-sm">Home</span>
          </Link>

          <div className="mb-8">
            <div className="flex items-center gap-3 mb-4">
              <Gift className="w-8 h-8 text-green-500" />
              <h1 className="text-2xl font-bold">Create Weekly Contract</h1>
            </div>
            <p className="text-sm text-gray-400">
              This week, if I reach my habits goal:
            </p>
          </div>

          <div className="space-y-6 mb-8">
            <div>
              <Label className="text-green-400 mb-2 block">🎁 REWARD</Label>
              <Input
                value={rewardText}
                onChange={(e) => setRewardText(e.target.value)}
                placeholder="I will treat myself to..."
                className="bg-gray-900 border-gray-800 text-white"
              />
            </div>

            <div>
              <Label className="text-red-400 mb-2 block">⚠️ SANCTION</Label>
              <Input
                value={sanctionText}
                onChange={(e) => setSanctionText(e.target.value)}
                placeholder="I will NOT allow myself..."
                className="bg-gray-900 border-gray-800 text-white"
              />
            </div>

            <div>
              <Label className="text-gray-400 mb-3 block">SUCCESS THRESHOLD</Label>
              <div className="mb-2">
                <Slider
                  value={[threshold]}
                  onValueChange={(v) => setThreshold(v[0])}
                  min={50}
                  max={100}
                  step={5}
                  className="mb-2"
                />
              </div>
              <div className="flex justify-between text-sm text-gray-500">
                <span>50%</span>
                <span className="font-semibold text-white">{threshold}%</span>
                <span>100%</span>
              </div>
            </div>
          </div>

          <div className="bg-yellow-950 border border-yellow-900 rounded-xl p-4 mb-6">
            <div className="text-sm text-yellow-400">
              ⚠️ By committing, you agree to honor this contract.
            </div>
          </div>

          <Button
            onClick={() => createMutation.mutate()}
            disabled={!rewardText || !sanctionText || createMutation.isPending}
            className="w-full bg-white text-black hover:bg-gray-200 h-12 text-base font-semibold"
          >
            {createMutation.isPending ? 'Creating...' : 'Commit to Contract'}
          </Button>
        </div>
      </div>
    );
  }

  // Contract created but not committed
  if (!contract.committed) {
    return (
      <div className="min-h-screen bg-black text-white p-6">
        <div className="max-w-md mx-auto">
          <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-gray-400 mb-8">
            <ArrowLeft className="w-4 h-4" />
            <span className="text-sm">Home</span>
          </Link>

          <div className="mb-8">
            <h1 className="text-2xl font-bold mb-2">Review Contract</h1>
            <p className="text-sm text-gray-400">Commit to make it active</p>
          </div>

          <div className="space-y-6 mb-8">
            <div className="p-4 rounded-lg bg-green-950 border border-green-900">
              <div className="text-sm text-green-400 mb-2">🎁 REWARD</div>
              <div className="font-medium">{contract.reward_text}</div>
            </div>

            <div className="p-4 rounded-lg bg-red-950 border border-red-900">
              <div className="text-sm text-red-400 mb-2">⚠️ SANCTION</div>
              <div className="font-medium">{contract.sanction_text}</div>
            </div>

            <div className="p-4 rounded-lg bg-gray-900">
              <div className="text-sm text-gray-400 mb-2">THRESHOLD</div>
              <div className="text-2xl font-bold">{contract.success_threshold_percentage}%</div>
            </div>
          </div>

          <Button
            onClick={() => commitMutation.mutate(contract.id)}
            disabled={commitMutation.isPending}
            className="w-full bg-white text-black hover:bg-gray-200 h-12 text-base font-semibold"
          >
            {commitMutation.isPending ? 'Committing...' : 'I Commit'}
          </Button>
        </div>
      </div>
    );
  }

  // Active contract
  return (
    <div className="min-h-screen bg-black text-white p-6">
      <div className="max-w-md mx-auto">
        <Link to={createPageUrl('Home')} className="inline-flex items-center gap-2 text-gray-400 mb-8">
          <ArrowLeft className="w-4 h-4" />
          <span className="text-sm">Home</span>
        </Link>

        <div className="mb-8">
          <h1 className="text-2xl font-bold mb-2">This Week's Contract</h1>
          <div className="text-sm text-gray-400">
            {format(weekStart, 'MMM d')} - {format(addDays(weekStart, 6), 'MMM d, yyyy')}
          </div>
        </div>

        {/* Progress Bar */}
        <div className="mb-8 p-6 rounded-xl bg-gradient-to-br from-gray-900 to-black border border-gray-800">
          <div className="text-sm text-gray-500 mb-2">CURRENT PERFORMANCE</div>
          <div className="text-4xl font-bold mb-4">
            {weeklyScore?.success_percentage || 0}%
          </div>
          <div className="h-3 bg-gray-800 rounded-full overflow-hidden mb-2">
            <div 
              className={`h-full transition-all ${
                (weeklyScore?.success_percentage || 0) >= contract.success_threshold_percentage
                  ? 'bg-gradient-to-r from-green-600 to-green-400'
                  : 'bg-gradient-to-r from-yellow-600 to-yellow-400'
              }`}
              style={{ width: `${weeklyScore?.success_percentage || 0}%` }}
            />
          </div>
          <div className="flex justify-between text-xs text-gray-500">
            <span>Threshold: {contract.success_threshold_percentage}%</span>
            <span>{daysRemaining} days remaining</span>
          </div>
        </div>

        <div className="space-y-4 mb-8">
          <div className="p-4 rounded-lg bg-green-950 border border-green-900">
            <div className="text-sm text-green-400 mb-2">🎁 REWARD</div>
            <div className="font-medium">{contract.reward_text}</div>
          </div>

          <div className="p-4 rounded-lg bg-red-950 border border-red-900">
            <div className="text-sm text-red-400 mb-2">⚠️ SANCTION</div>
            <div className="font-medium">{contract.sanction_text}</div>
          </div>
        </div>

        {weeklyScore && weeklyScore.success_percentage < contract.success_threshold_percentage && (
          <div className="p-4 rounded-lg bg-yellow-950 border border-yellow-900">
            <div className="text-sm text-yellow-400">
              💡 {daysRemaining} days left! Stay consistent to earn your reward.
            </div>
          </div>
        )}

        {weeklyScore && weeklyScore.success_percentage >= contract.success_threshold_percentage && (
          <div className="p-4 rounded-lg bg-green-950 border border-green-900">
            <div className="text-sm text-green-400">
              ✓ You're on track! Keep it up to secure your reward.
            </div>
          </div>
        )}
      </div>
    </div>
  );
}