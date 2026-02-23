import React, { useState } from 'react';
import { format, startOfMonth, endOfMonth, startOfWeek, endOfWeek, addDays, addMonths, isSameMonth, isSameDay, isToday, isFuture, isPast, startOfDay } from 'date-fns';
import { fr, es, zhCN, hi, id as idLocale, ru, ar, pt } from 'date-fns/locale';
import { ChevronLeft, ChevronRight, Plus, ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useLanguage } from '../LanguageProvider';

const colorMap = {
  blue: { bg: 'bg-blue-100/80', text: 'text-blue-700', border: 'border-blue-300/60', darkBg: 'bg-blue-900/30', darkText: 'text-blue-300', darkBorder: 'border-blue-700/40' },
  green: { bg: 'bg-green-100/80', text: 'text-green-700', border: 'border-green-300/60', darkBg: 'bg-green-900/30', darkText: 'text-green-300', darkBorder: 'border-green-700/40' },
  purple: { bg: 'bg-purple-100/80', text: 'text-purple-700', border: 'border-purple-300/60', darkBg: 'bg-purple-900/30', darkText: 'text-purple-300', darkBorder: 'border-purple-700/40' },
  pink: { bg: 'bg-pink-100/80', text: 'text-pink-700', border: 'border-pink-300/60', darkBg: 'bg-pink-900/30', darkText: 'text-pink-300', darkBorder: 'border-pink-700/40' },
  orange: { bg: 'bg-orange-100/80', text: 'text-orange-700', border: 'border-orange-300/60', darkBg: 'bg-orange-900/30', darkText: 'text-orange-300', darkBorder: 'border-orange-700/40' },
  red: { bg: 'bg-red-100/80', text: 'text-red-700', border: 'border-red-300/60', darkBg: 'bg-red-900/30', darkText: 'text-red-300', darkBorder: 'border-red-700/40' },
  yellow: { bg: 'bg-yellow-100/80', text: 'text-yellow-700', border: 'border-yellow-300/60', darkBg: 'bg-yellow-900/30', darkText: 'text-yellow-300', darkBorder: 'border-yellow-700/40' },
  teal: { bg: 'bg-teal-100/80', text: 'text-teal-700', border: 'border-teal-300/60', darkBg: 'bg-teal-900/30', darkText: 'text-teal-300', darkBorder: 'border-teal-700/40' }
};

export default function CalendarView({ events, onEventClick, onNewEvent, onTimeClick, onDateChange, eventTypes = [] }) {
  const { language, t } = useLanguage();
  const [currentDate, setCurrentDate] = useState(new Date());
  const [view, setView] = useState('yearly');
  
  const getEventColor = (event) => {
    if (event.is_birthday) {
      return { 
        bg: 'bg-gradient-to-r from-pink-500 via-yellow-400 to-purple-500', 
        text: 'text-white font-bold', 
        border: 'border-yellow-400/80 shadow-[0_0_20px_rgba(253,224,71,0.5),0_0_40px_rgba(236,72,153,0.3),inset_0_2px_6px_rgba(255,255,255,0.2)]', 
        darkBg: 'bg-gradient-to-r from-pink-600/90 via-yellow-500/90 to-purple-600/90', 
        darkText: 'text-white font-bold', 
        darkBorder: 'border-yellow-400/80 shadow-[0_0_20px_rgba(253,224,71,0.4),0_0_40px_rgba(236,72,153,0.2),inset_0_2px_6px_rgba(255,255,255,0.15)]'
      };
    }
    if (event.event_type_id) {
      const type = eventTypes.find(t => t.id === event.event_type_id);
      if (type) {
        return colorMap[type.color] || colorMap.blue;
      }
    }
    return colorMap.blue;
  };
  
  const getDateFnsLocale = () => {
    const locales = { fr, es, zh: zhCN, hi, id: idLocale, ru, ar, pt };
    return locales[language] || undefined;
  };

  const getEventsForDate = (date) => {
    const dateStr = format(date, 'yyyy-MM-dd');
    return events?.filter(e => e.event_date === dateStr) || [];
  };

  const renderYearlyView = () => {
    const year = currentDate.getFullYear();
    const months = [];
    
    for (let month = 0; month < 12; month++) {
      const monthDate = new Date(year, month, 1);
      const monthStart = startOfMonth(monthDate);
      const monthEnd = endOfMonth(monthStart);
      
      // Count events in this month
      let eventCount = 0;
      let day = monthStart;
      while (day <= monthEnd) {
        const dayEvents = getEventsForDate(day);
        eventCount += dayEvents.length;
        day = addDays(day, 1);
      }
      
      months.push(
        <button
          key={month} 
          onClick={() => {
            setCurrentDate(monthDate);
            setView('monthly');
          }}
          className="relative p-5 h-24 bg-zinc-900/60 rounded-xl border border-zinc-800/50 hover:bg-zinc-900/80 hover:border-zinc-700/60 active:scale-[0.98] transition-all duration-150 flex flex-col items-center justify-center"
        >
          <div className="text-center font-bold text-zinc-300 text-base mb-1">
            {format(monthDate, 'MMM', { locale: getDateFnsLocale() })}
          </div>
          {eventCount > 0 && (
            <div className="text-center">
              <div className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-blue-500/20 border border-blue-500/40">
                <span className="text-xs font-bold text-blue-400">{eventCount}</span>
              </div>
            </div>
          )}
        </button>
      );
    }
    
    return <div className="grid grid-cols-3 gap-3">{months}</div>;
  };

  const renderMonthlyView = () => {
    const monthStart = startOfMonth(currentDate);
    const monthEnd = endOfMonth(monthStart);
    const startDate = startOfWeek(monthStart, { weekStartsOn: 1 });
    const endDate = endOfWeek(monthEnd, { weekStartsOn: 1 });

    const rows = [];
    let days = [];
    let day = startDate;
    const today = startOfDay(new Date());
    const weekDaysLabels = [t('monday'), t('tuesday'), t('wednesday'), t('thursday'), t('friday'), t('saturday'), t('sunday')];

    while (day <= endDate) {
      for (let i = 0; i < 7; i++) {
        const dayEvents = getEventsForDate(day);
        const isCurrentMonth = isSameMonth(day, monthStart);
        const isCurrentDay = isToday(day);
        const isFutureDay = isFuture(day) && !isCurrentDay;
        const isPastDay = isPast(day) && !isCurrentDay;
        
        const clickDay = day;
        days.push(
          <button
            key={day.toString()}
            onClick={() => {
              setCurrentDate(clickDay);
              setView('daily');
              onDateChange?.(clickDay);
            }}
            className={`relative min-h-20 p-1.5 border transition-all duration-150 text-left ${
              !isCurrentMonth 
                ? 'bg-zinc-950/30 border-zinc-900/30 opacity-30' 
                : isCurrentDay
                ? 'bg-gradient-to-br from-blue-950/80 to-purple-950/80 border-blue-700/60 shadow-[0_8px_24px_rgba(59,130,246,0.3),inset_0_1px_0_rgba(59,130,246,0.1)] scale-105'
                : 'bg-zinc-900/60 border-zinc-800/50 hover:bg-zinc-900/80 hover:border-zinc-700/60 active:scale-[0.98]'
            }`}
          >
            {isCurrentDay && (
              <div className="absolute inset-0 bg-gradient-to-br from-blue-600/10 to-purple-600/10 rounded" />
            )}
            <div className={`relative text-xs font-bold mb-1 ${
              isCurrentDay 
                ? 'text-blue-300' 
                : isCurrentMonth 
                ? isPastDay ? 'text-zinc-500' : 'text-white' 
                : 'text-zinc-700'
            }`}>
              {format(day, 'd')}
            </div>
            <div className="relative space-y-0.5">
              {dayEvents.slice(0, 2).map(event => {
                const eventColor = getEventColor(event);
                return (
                  <div key={event.id} className={`text-[6px] px-0.5 py-0.5 rounded font-medium transition-all border leading-tight ${
                    isCurrentDay
                      ? `${event.is_birthday ? eventColor.bg : eventColor.bg} ${eventColor.text} ${eventColor.border} shadow-[0_0_8px_rgba(59,130,246,0.3)]`
                      : `${event.is_birthday ? eventColor.darkBg : eventColor.darkBg} ${eventColor.darkText} ${eventColor.darkBorder}`
                  }`}>
                    <div className="truncate">
                      {event.is_birthday ? '🎂' : event.title}
                    </div>
                  </div>
                );
              })}
              {dayEvents.length > 2 && (
                <div className={`text-[6px] font-semibold ${isCurrentDay ? 'text-blue-400' : 'text-zinc-600'}`}>
                  +{dayEvents.length - 2}
                </div>
              )}
            </div>
          </button>
        );
        day = addDays(day, 1);
      }
      rows.push(
        <div key={day.toString()} className="grid grid-cols-7 gap-2">
          {days}
        </div>
      );
      days = [];
    }

    return (
      <div>
        <div className="grid grid-cols-7 gap-2 mb-4">
          {weekDaysLabels.map(dayLabel => (
            <div key={dayLabel} className="text-center text-[10px] font-black text-zinc-700 uppercase tracking-widest py-2">
              {dayLabel}
            </div>
          ))}
        </div>
        <div className="space-y-2">
          {rows}
        </div>
      </div>
    );
  };

  const renderDailyView = () => {
    const dayEvents = getEventsForDate(currentDate);
    const isCurrentDay = isToday(currentDate);
    const birthdayEvents = dayEvents.filter(e => e.is_birthday);
    const regularEvents = dayEvents.filter(e => !e.is_birthday);
    
    // Get next few hours if today
    const now = new Date();
    const currentHour = now.getHours();
    const hours = isCurrentDay 
      ? Array.from({ length: 8 }, (_, i) => (currentHour + i) % 24).filter(h => h >= currentHour && h < 24)
      : Array.from({ length: 24 }, (_, i) => i);
    
    return (
      <div className="relative">
        <div className="absolute inset-0 bg-gradient-to-r from-zinc-700/10 to-zinc-600/10 rounded-2xl blur-xl" />
        <div className="relative rounded-2xl bg-zinc-900/60 border border-zinc-800/50 overflow-hidden shadow-[0_12px_48px_rgba(0,0,0,0.5)]">
          <div className="bg-gradient-to-r from-zinc-900/80 to-zinc-850/80 text-center py-5 border-b border-zinc-800/50">
            <div className={`text-xl font-black tracking-tight ${isCurrentDay ? 'text-blue-300' : 'text-white'}`}>
              {format(currentDate, 'EEEE, MMM d', { locale: getDateFnsLocale() })}
            </div>
          </div>
          
          {birthdayEvents.length > 0 && (
          <div className="p-4 border-b border-zinc-800/50">
            {birthdayEvents.map(event => (
              <div key={event.id} className="p-4 rounded-xl bg-gradient-to-br from-pink-500 via-yellow-400 to-purple-500 border-2 border-yellow-400/80 shadow-[0_0_24px_rgba(253,224,71,0.5),0_6px_20px_rgba(236,72,153,0.4),inset_0_2px_6px_rgba(255,255,255,0.2)] mb-3 last:mb-0">
                <div className="text-center">
                  <div className="text-3xl mb-2">🎂✨🎉</div>
                  <div className="text-lg font-bold text-white drop-shadow-[0_2px_8px_rgba(0,0,0,0.5)] mb-1">{event.birthday_person_name}</div>
                  {event.birthday_relationship && (
                    <div className="text-xs text-white/90 mb-2">{event.birthday_relationship}</div>
                  )}
                  {event.birthday_notes && (
                    <div className="text-xs text-white/80 mt-2 italic">{event.birthday_notes}</div>
                  )}
                </div>
              </div>
            ))}
          </div>
          )}
          
          <div className="max-h-[500px] overflow-y-auto">
            {hours.map(hour => {
              const hourEvents = regularEvents.filter(e => parseInt(e.event_time.split(':')[0]) === hour);
              const hasEvents = hourEvents.length > 0;
              
              return (
                <button
                  key={hour}
                  onClick={() => {
                    if (onTimeClick) {
                      const timeStr = format(new Date().setHours(hour, 0), 'HH:mm');
                      onTimeClick(format(currentDate, 'yyyy-MM-dd'), timeStr);
                    }
                  }}
                  className={`w-full flex border-b border-zinc-900/50 hover:bg-zinc-900/60 active:scale-[0.99] transition-all duration-150 ${
                    hasEvents ? 'bg-zinc-900/40' : 'bg-transparent'
                  }`}
                >
                  <div className="w-16 text-right pr-4 py-3 text-xs text-zinc-700 font-bold tabular-nums">
                    {format(new Date().setHours(hour, 0), 'HH:mm')}
                  </div>
                  <div className="flex-1 p-3 min-h-16 text-left">
                   {hourEvents.map(event => {
                     const eventColor = getEventColor(event);
                     return (
                       <div
                         key={event.id}
                         className={`p-3 rounded-xl border shadow-[0_4px_16px_rgba(59,130,246,0.2)] mb-2 last:mb-0 ${
                           event.is_birthday
                             ? `${eventColor.darkBg} ${eventColor.darkBorder}`
                             : `${eventColor.darkBg} ${eventColor.darkBorder}`
                         }`}
                       >
                         <div className={`text-sm font-bold mb-1 ${event.is_birthday ? eventColor.darkText : eventColor.darkText}`}>
                           {event.is_birthday ? '🎂 ' : ''}{event.is_birthday ? event.birthday_person_name : event.title}
                         </div>
                         <div className={`text-xs font-medium ${event.is_birthday ? 'text-pink-400/60' : eventColor.darkText}`}>
                           {event.is_birthday 
                             ? (event.birthday_relationship ? event.birthday_relationship : 'Toute la journée')
                             : `${event.event_time} • ${event.duration_minutes}min`
                           }
                         </div>
                       </div>
                     );
                   })}
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      </div>
    );
  };

  const navigatePrev = () => {
    let newDate;
    if (view === 'yearly') {
      newDate = new Date(currentDate.getFullYear() - 1, 0, 1);
    } else if (view === 'monthly') {
      newDate = addMonths(currentDate, -1);
    } else if (view === 'weekly') {
      newDate = addDays(currentDate, -7);
    } else if (view === 'daily') {
      newDate = addDays(currentDate, -1);
    }
    setCurrentDate(newDate);
    onDateChange?.(newDate);
  };

  const navigateNext = () => {
    let newDate;
    if (view === 'yearly') {
      newDate = new Date(currentDate.getFullYear() + 1, 0, 1);
    } else if (view === 'monthly') {
      newDate = addMonths(currentDate, 1);
    } else if (view === 'weekly') {
      newDate = addDays(currentDate, 7);
    } else if (view === 'daily') {
      newDate = addDays(currentDate, 1);
    }
    setCurrentDate(newDate);
    onDateChange?.(newDate);
  };

  const getHeaderText = () => {
    const locale = getDateFnsLocale();
    if (view === 'yearly') return currentDate.getFullYear();
    if (view === 'monthly') return format(currentDate, 'MMMM yyyy', { locale });
    if (view === 'weekly') {
      const weekStart = startOfWeek(currentDate, { weekStartsOn: 1 });
      const weekEnd = addDays(weekStart, 6);
      return `${format(weekStart, 'MMM d', { locale })} - ${format(weekEnd, 'MMM d, yyyy', { locale })}`;
    }
    if (view === 'daily') return format(currentDate, 'MMMM d, yyyy', { locale });
  };

  const handleBackNavigation = () => {
    if (view === 'daily') {
      setView('monthly');
    } else if (view === 'monthly') {
      setView('yearly');
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-2">
          {(view === 'monthly' || view === 'daily') && (
            <button
              onClick={handleBackNavigation}
              className="p-2 rounded-xl bg-zinc-900/60 border border-zinc-800/50 hover:bg-zinc-900/80 hover:border-zinc-700/60 active:scale-95 transition-all duration-150"
            >
              <ArrowLeft className="w-4 h-4" />
            </button>
          )}
          <div className="flex items-center gap-2">
            <button
              onClick={navigatePrev}
              className="p-2 rounded-xl bg-zinc-900/60 border border-zinc-800/50 hover:bg-zinc-900/80 hover:border-zinc-700/60 active:scale-95 transition-all duration-150"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <h2 className="text-base font-bold min-w-32 text-center">{getHeaderText()}</h2>
            <button
              onClick={navigateNext}
              className="p-2 rounded-xl bg-zinc-900/60 border border-zinc-800/50 hover:bg-zinc-900/80 hover:border-zinc-700/60 active:scale-95 transition-all duration-150"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
        <Button
          onClick={onNewEvent}
          className="bg-white text-black hover:bg-zinc-200 h-9 px-3 text-xs font-bold rounded-xl shadow-[0_8px_24px_rgba(255,255,255,0.12)] active:scale-95 transition-all duration-150"
        >
          <Plus className="w-4 h-4" />
        </Button>
      </div>

      {view === 'yearly' && renderYearlyView()}
      {view === 'monthly' && renderMonthlyView()}
      {view === 'daily' && renderDailyView()}
    </div>
  );
}