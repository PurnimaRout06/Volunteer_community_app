// models/Event.js
// ─────────────────────────────────────────────────────────────────────────────
// Event schema — represents an event created by an organizer.
// Used by the Home tab (create/edit/delete/featured) and Search tab.
// ─────────────────────────────────────────────────────────────────────────────

const mongoose = require("mongoose");

const EventSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, "Event title is required"],
      trim: true,
    },

    description: {
      type: String,
      default: "",
    },

    // e.g. "Music", "Tech", "Sports", "Food" — used for filtering
    category: {
      type: String,
      default: null,
    },

    location: {
      type: String,
      default: null,
    },

    date: {
      type: Date,
      required: [true, "Event date is required"],
    },

    time: {
      type: String,   // e.g. "6:00 PM" — stored as string for flexibility
      default: null,
    },

    imageUrl: {
      type: String,
      default: null,
    },

    // true = shown as the featured event on the Home tab
    isFeatured: {
      type: Boolean,
      default: false,
    },

    // Reference to the User who created this event
    organizer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    // Array of User IDs who registered for this event
    attendees: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Event", EventSchema);
