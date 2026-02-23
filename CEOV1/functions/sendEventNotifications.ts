import { createClientFromRequest } from 'npm:@base44/sdk@0.8.6';

Deno.serve(async (req) => {
  try {
    const base44 = createClientFromRequest(req);
    
    // Vérifier que l'utilisateur est admin (car c'est une tâche planifiée)
    const user = await base44.auth.me();
    if (user?.role !== 'admin') {
      return Response.json({ error: 'Forbidden: Admin access required' }, { status: 403 });
    }

    console.log('[sendEventNotifications] Starting notification check...');
    
    // Récupérer tous les événements
    const allEvents = await base44.asServiceRole.entities.CalendarEvent.list();
    console.log(`[sendEventNotifications] Found ${allEvents.length} total events`);
    
    const now = new Date();
    const notificationsSent = {
      evening_before: 0,
      morning_of: 0,
      birthday_morning: 0
    };
    
    for (const event of allEvents) {
      const eventDate = new Date(`${event.event_date}T${event.event_time}`);
      const eventDateOnly = new Date(event.event_date);
      
      // Calculer les dates de notification
      const eveningBefore = new Date(eventDateOnly);
      eveningBefore.setDate(eveningBefore.getDate() - 1);
      eveningBefore.setHours(19, 0, 0, 0); // 19h la veille
      
      const morningOf = new Date(eventDateOnly);
      morningOf.setHours(8, 0, 0, 0); // 8h le matin même
      
      // Pour les anniversaires : uniquement notification le matin même
      if (event.is_birthday) {
        if (!event.notification_birthday_morning_sent && now >= morningOf && now < new Date(morningOf.getTime() + 60 * 60 * 1000)) {
          // Envoyer notification anniversaire
          const userEmail = event.created_by;
          await base44.asServiceRole.integrations.Core.SendEmail({
            to: userEmail,
            subject: `🎂 Anniversaire aujourd'hui : ${event.birthday_person_name}`,
            body: `
              <h2>🎂 Joyeux anniversaire !</h2>
              <p>Aujourd'hui c'est l'anniversaire de <strong>${event.birthday_person_name}</strong> ${event.birthday_relationship ? `(${event.birthday_relationship})` : ''}!</p>
              ${event.birthday_notes ? `<p>Notes : ${event.birthday_notes}</p>` : ''}
              <p>N'oubliez pas de souhaiter un bon anniversaire !</p>
            `
          });
          
          await base44.asServiceRole.entities.CalendarEvent.update(event.id, {
            notification_birthday_morning_sent: true
          });
          
          notificationsSent.birthday_morning++;
          console.log(`[sendEventNotifications] Sent birthday morning notification for: ${event.birthday_person_name}`);
        }
      } else {
        // Pour les événements normaux : notification veille au soir + matin même
        
        // Notification la veille au soir
        if (!event.notification_evening_before_sent && now >= eveningBefore && now < new Date(eveningBefore.getTime() + 60 * 60 * 1000)) {
          const userEmail = event.created_by;
          await base44.asServiceRole.integrations.Core.SendEmail({
            to: userEmail,
            subject: `📅 Événement demain : ${event.title}`,
            body: `
              <h2>📅 Rappel : Événement demain</h2>
              <p><strong>${event.title}</strong></p>
              <p>Date : ${format(eventDate, 'dd/MM/yyyy')} à ${event.event_time}</p>
              <p>Durée : ${event.duration_minutes} minutes</p>
              ${event.description ? `<p>Détails : ${event.description}</p>` : ''}
              <p>Préparez-vous pour demain !</p>
            `
          });
          
          await base44.asServiceRole.entities.CalendarEvent.update(event.id, {
            notification_evening_before_sent: true
          });
          
          notificationsSent.evening_before++;
          console.log(`[sendEventNotifications] Sent evening before notification for: ${event.title}`);
        }
        
        // Notification le matin même
        if (!event.notification_morning_of_sent && now >= morningOf && now < new Date(morningOf.getTime() + 60 * 60 * 1000)) {
          const userEmail = event.created_by;
          await base44.asServiceRole.integrations.Core.SendEmail({
            to: userEmail,
            subject: `📅 Événement aujourd'hui : ${event.title}`,
            body: `
              <h2>📅 Aujourd'hui : ${event.title}</h2>
              <p>Heure : ${event.event_time}</p>
              <p>Durée : ${event.duration_minutes} minutes</p>
              ${event.description ? `<p>Détails : ${event.description}</p>` : ''}
              <p>Bonne journée !</p>
            `
          });
          
          await base44.asServiceRole.entities.CalendarEvent.update(event.id, {
            notification_morning_of_sent: true
          });
          
          notificationsSent.morning_of++;
          console.log(`[sendEventNotifications] Sent morning of notification for: ${event.title}`);
        }
      }
    }
    
    console.log('[sendEventNotifications] Notifications sent:', notificationsSent);
    
    return Response.json({ 
      success: true, 
      notifications_sent: notificationsSent,
      total: notificationsSent.evening_before + notificationsSent.morning_of + notificationsSent.birthday_morning
    });
  } catch (error) {
    console.error('[sendEventNotifications] Error:', error);
    return Response.json({ error: error.message }, { status: 500 });
  }
});