// controllers/notificationController.js
// ─────────────────────────────────────────────────────────────────────────────
// Handles the Notifications tab.
// ─────────────────────────────────────────────────────────────────────────────

const Notification = require("../models/Notification");
const Event        = require("../models/Event");

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/notifications
// Returns all notifications for the logged-in user (newest first).
// ─────────────────────────────────────────────────────────────────────────────
async function getNotifications(req, res) {
  try {
    const notifications = await Notification.find({ user: req.user.id })
      .sort({ createdAt: -1 })
      .populate("event", "title date");

    const unreadCount = notifications.filter((n) => !n.isRead).length;
    return res.status(200).json({ notifications, unreadCount });
  } catch (err) {
    console.error("getNotifications error:", err);
    return res.status(500).json({ error: "Failed to fetch notifications." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PATCH /api/notifications/:id/read
// Mark a single notification as read.
// ─────────────────────────────────────────────────────────────────────────────
async function markAsRead(req, res) {
  try {
    // findOneAndUpdate with user check ensures a user can only mark their own notifications
    const notif = await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.user.id },
      { isRead: true },
      { new: true }
    );
    if (!notif) return res.status(404).json({ error: "Notification not found." });
    return res.status(200).json({ message: "Notification marked as read." });
  } catch (err) {
    console.error("markAsRead error:", err);
    return res.status(500).json({ error: "Failed to mark notification as read." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PATCH /api/notifications/read-all
// Mark ALL notifications as read for the logged-in user.
// ─────────────────────────────────────────────────────────────────────────────
async function markAllAsRead(req, res) {
  try {
    await Notification.updateMany({ user: req.user.id, isRead: false }, { isRead: true });
    return res.status(200).json({ message: "All notifications marked as read." });
  } catch (err) {
    console.error("markAllAsRead error:", err);
    return res.status(500).json({ error: "Failed to mark all notifications as read." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/notifications/send
// Organizer broadcasts an update notification to all event attendees.
// Body: { eventId, title, body }
// ─────────────────────────────────────────────────────────────────────────────
async function sendEventNotification(req, res) {
  try {
    const { eventId, title, body } = req.body;
    if (!eventId || !title) return res.status(400).json({ error: "eventId and title are required." });

    const event = await Event.findById(eventId);
    if (!event) return res.status(404).json({ error: "Event not found." });

    // Only the organizer can send notifications to attendees
    if (event.organizer.toString() !== req.user.id) {
      return res.status(403).json({ error: "Only the event organizer can send notifications." });
    }

    // Build one notification document per attendee
    const notifDocs = event.attendees.map((userId) => ({
      user:  userId,
      type:  "update",
      title,
      body:  body || "",
      event: event._id,
    }));

    await Notification.insertMany(notifDocs);
    return res.status(200).json({ message: `Notification sent to ${notifDocs.length} attendees.` });
  } catch (err) {
    console.error("sendEventNotification error:", err);
    return res.status(500).json({ error: "Failed to send notifications." });
  }
}

module.exports = { getNotifications, markAsRead, markAllAsRead, sendEventNotification };
