/**
 * CONQUER — Notification Service (FCM & In-App Alerts)
 */

const notificationsMemory = []; // Fallback in-memory notification queue

function createNotification({ userId, type, title, message, relatedUserId, relatedTerritoryId }) {
  const notif = {
    id: 'notif_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6),
    userId,
    type: type || 'system', // 'attack', 'conquest', 'achievement', 'streak', 'system'
    title,
    message,
    relatedUserId,
    relatedTerritoryId,
    read: false,
    createdAt: new Date()
  };

  notificationsMemory.unshift(notif);
  return notif;
}

function sendTerritoryAttackAlert(defenderId, attackerName, lostAreaKm2, territoryId) {
  return createNotification({
    userId: defenderId,
    type: 'attack',
    title: '🚨 TERRITORY UNDER ATTACK',
    message: `${attackerName} captured ${lostAreaKm2.toFixed(2)} km² of your territory!`,
    relatedTerritoryId: territoryId
  });
}

function getUserNotifications(userId) {
  return notificationsMemory.filter(n => n.userId.toString() === userId.toString());
}

module.exports = {
  createNotification,
  sendTerritoryAttackAlert,
  getUserNotifications
};
