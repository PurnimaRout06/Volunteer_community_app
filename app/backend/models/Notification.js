// models/Notification.js
// ─────────────────────────────────────────────────────────────────────────────
// Notification schema — system messages sent to users.
// Types:
//   "confirmation" — sent when a user registers for an event
//   "reminder"     — sent before an event starts
//   "update"       — sent by an organizer to all attendees
// ─────────────────────────────────────────────────────────────────────────────

const mongoose = require("mongoose");

const NotificationSchema = new mongoose.Schema(
  {
    // The user who receives this notification
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    // What kind of notification this is
    type: {
      type: String,
      enum: ["confirmation", "reminder", "update"],
      required: true,
    },

    title: {
      type: String,
      required: true,
    },

    body: {
      type: String,
      default: "",
    },

    // false = unread (shows badge), true = read
    isRead: {
      type: Boolean,
      default: false,
    },

    // Optional: the event this notification is related to
    event: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Event",
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Notification", NotificationSchema);
