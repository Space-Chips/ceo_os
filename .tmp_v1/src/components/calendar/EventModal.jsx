import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { format } from 'date-fns';
import { Cake } from 'lucide-react';
import { useLanguage } from '../LanguageProvider';
import { usePremium } from '../PremiumProvider';
import { canAccessAdvancedCalendar } from '../premiumLimits';

const colorMap = {
  blue: { bg: 'bg-blue-500', border: 'border-blue-500', text: 'text-blue-400' },
  green: { bg: 'bg-green-500', border: 'border-green-500', text: 'text-green-400' },
  purple: { bg: 'bg-purple-500', border: 'border-purple-500', text: 'text-purple-400' },
  pink: { bg: 'bg-pink-500', border: 'border-pink-500', text: 'text-pink-400' },
  orange: { bg: 'bg-orange-500', border: 'border-orange-500', text: 'text-orange-400' },
  red: { bg: 'bg-red-500', border: 'border-red-500', text: 'text-red-400' },
  yellow: { bg: 'bg-yellow-500', border: 'border-yellow-500', text: 'text-yellow-400' },
  teal: { bg: 'bg-teal-500', border: 'border-teal-500', text: 'text-teal-400' }
};

export default function EventModal({ open, onClose, onSubmit, initialData, eventTypes = [] }) {
  const { t } = useLanguage();
  const { isPremiumUser } = usePremium();
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    event_date: format(new Date(), 'yyyy-MM-dd'),
    event_time: '09:00',
    duration_minutes: 60,
    is_birthday: false,
    birthday_person_name: '',
    birthday_relationship: '',
    birthday_notes: '',
    event_type_id: null
  });

  useEffect(() => {
    if (initialData) {
      setFormData(prev => ({ ...prev, ...initialData }));
    }
  }, [initialData]);

  useEffect(() => {
    if (open) {
      setFormData({
        title: '',
        description: '',
        event_date: format(new Date(), 'yyyy-MM-dd'),
        event_time: '09:00',
        duration_minutes: 60,
        is_birthday: false,
        birthday_person_name: '',
        birthday_relationship: '',
        birthday_notes: '',
        event_type_id: null,
        ...initialData
      });
    }
  }, [open]);

  const handleSubmit = (e) => {
    e.preventDefault();
    const dataToSubmit = { ...formData };
    if (formData.is_birthday) {
      const year = new Date(formData.event_date).getFullYear();
      dataToSubmit.birthday_base_year = year;
    }
    onSubmit(dataToSubmit);
    setFormData({
      title: '',
      description: '',
      event_date: format(new Date(), 'yyyy-MM-dd'),
      event_time: '09:00',
      duration_minutes: 60,
      is_birthday: false,
      birthday_person_name: '',
      birthday_relationship: '',
      birthday_notes: ''
    });
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="bg-zinc-900 border-zinc-800 text-white">
        <DialogHeader>
          <DialogTitle>{t('createNewEvent')}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <button
            type="button"
            onClick={() => {
              if (!isPremiumUser && !canAccessAdvancedCalendar(isPremiumUser).allowed) {
                return;
              }
              setFormData({ ...formData, is_birthday: !formData.is_birthday });
            }}
            disabled={!isPremiumUser && !canAccessAdvancedCalendar(isPremiumUser).allowed}
            className={`w-full flex items-center gap-3 p-4 rounded-xl border-2 transition-all duration-200 ${
              formData.is_birthday
                ? 'bg-gradient-to-br from-pink-950/60 to-purple-950/60 border-pink-500/50 shadow-[0_0_20px_rgba(236,72,153,0.3)]'
                : (!isPremiumUser && !canAccessAdvancedCalendar(isPremiumUser).allowed)
                ? 'bg-zinc-900/30 border-zinc-800/40 opacity-50 cursor-not-allowed'
                : 'bg-zinc-800/30 border-zinc-700/50 hover:border-zinc-600/50'
            }`}
          >
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center transition-all ${
              formData.is_birthday
                ? 'bg-gradient-to-br from-pink-500 to-purple-500 shadow-lg'
                : 'bg-zinc-700/50'
            }`}>
              <Cake className={`w-5 h-5 ${formData.is_birthday ? 'text-white' : 'text-zinc-400'}`} />
            </div>
            <div className="flex-1 text-left">
              <div className={`font-bold text-sm ${formData.is_birthday ? 'text-pink-200' : 'text-zinc-400'}`}>
                🎂 {t('birthday')}
                {!isPremiumUser && !canAccessAdvancedCalendar(isPremiumUser).allowed && (
                  <span className="ml-2 text-xs text-amber-400 font-semibold">Premium</span>
                )}
              </div>
              <div className="text-xs text-zinc-500">
                {formData.is_birthday ? t('modeActivated') : t('clickToActivate')}
              </div>
            </div>
          </button>

          {formData.is_birthday ? (
            <>
              <div>
                <label className="text-sm text-zinc-400 mb-2 block">{t('personName')}</label>
                <Input
                  value={formData.birthday_person_name}
                  onChange={(e) => setFormData({ ...formData, birthday_person_name: e.target.value })}
                  placeholder="e.g., Marie"
                  className="bg-zinc-800 border-zinc-700"
                  required
                />
              </div>

              <div>
                <label className="text-sm text-zinc-400 mb-2 block">{t('relationship')}</label>
                <Input
                  value={formData.birthday_relationship}
                  onChange={(e) => setFormData({ ...formData, birthday_relationship: e.target.value })}
                  placeholder="e.g., Amie, Collègue, Famille"
                  className="bg-zinc-800 border-zinc-700"
                />
              </div>

              <div>
                <label className="text-sm text-zinc-400 mb-2 block">{t('notesOptional')}</label>
                <Textarea
                  value={formData.birthday_notes}
                  onChange={(e) => setFormData({ ...formData, birthday_notes: e.target.value })}
                  placeholder={t('giftPreferences')}
                  className="bg-zinc-800 border-zinc-700"
                />
              </div>
            </>
          ) : (
            <>
              <div>
                <label className="text-sm text-zinc-400 mb-2 block">{t('titleEvent')}</label>
                <Input
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  placeholder={t('teamMeeting')}
                  className="bg-zinc-800 border-zinc-700"
                  required
                />
              </div>

              <div>
                <label className="text-sm text-zinc-400 mb-2 block">{t('descriptionOptional')}</label>
                <Textarea
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder={t('addEventDetails')}
                  className="bg-zinc-800 border-zinc-700"
                />
              </div>
            </>
          )}

          {/* Event Type Selection */}
          {!formData.is_birthday && eventTypes.length > 0 && (
            <div>
              <label className="text-sm text-zinc-400 mb-2 block">Event Type (Optional)</label>
              <div className="flex gap-2 flex-wrap">
                {eventTypes.slice(0, 3).map(type => {
                  const colorConfig = colorMap[type.color] || colorMap.blue;
                  const isSelected = formData.event_type_id === type.id;
                  return (
                    <button
                      key={type.id}
                      type="button"
                      onClick={() => setFormData({ ...formData, event_type_id: isSelected ? null : type.id })}
                      className={`px-4 py-2 rounded-xl text-xs font-bold transition-all duration-150 ${
                        isSelected
                          ? `${colorConfig.bg} ${colorConfig.border} border-2 shadow-lg scale-105 text-white`
                          : 'bg-zinc-800/50 border-2 border-zinc-700/50 text-zinc-400 hover:border-zinc-600'
                      }`}
                    >
                      {type.name}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          <div className={formData.is_birthday ? "grid grid-cols-1 gap-4" : "grid grid-cols-2 gap-4"}>
            <div>
              <label className="text-sm text-zinc-400 mb-2 block">{t('date')}</label>
              <Input
                type="date"
                value={formData.event_date}
                onChange={(e) => setFormData({ ...formData, event_date: e.target.value })}
                className="bg-zinc-800 border-zinc-700"
                required
              />
            </div>

            {!formData.is_birthday && (
              <div>
                <label className="text-sm text-zinc-400 mb-2 block">{t('time')}</label>
                <Input
                  type="time"
                  value={formData.event_time}
                  onChange={(e) => setFormData({ ...formData, event_time: e.target.value })}
                  className="bg-zinc-800 border-zinc-700"
                  required
                />
              </div>
            )}
          </div>

          {!formData.is_birthday && (
            <div>
              <label className="text-sm text-zinc-400 mb-2 block">{t('durationMinutes')}</label>
              <Input
                type="number"
                value={formData.duration_minutes}
                onChange={(e) => setFormData({ ...formData, duration_minutes: parseInt(e.target.value) })}
                min="15"
                step="15"
                className="bg-zinc-800 border-zinc-700"
                required
              />
            </div>
          )}

          <div className="flex gap-3 pt-4">
            <Button type="button" variant="outline" onClick={onClose} className="flex-1">
              {t('cancel')}
            </Button>
            <Button type="submit" className="flex-1 bg-white text-black hover:bg-zinc-200">
              {formData.is_birthday ? t('createBirthday') : t('createEvent')}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}