// controllers/userController.js
// ─────────────────────────────────────────────────────────────────────────────
// Handles user profile data and event registration.
// ─────────────────────────────────────────────────────────────────────────────

const User         = require("../models/User");
const Event        = require("../models/Event");
const Notification = require("../models/Notification");

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/users/profile
// Returns the logged-in user's profile (username, email, points, avatar).
// ─────────────────────────────────────────────────────────────────────────────
async function getProfile(req, res) {
  try {
    const user = await User.findById(req.user.id).select("-password -googleId");
    if (!user) return res.status(404).json({ error: "User not found." });
    return res.status(200).json({ user });
  } catch (err) {
    console.error("getProfile error:", err);
    return res.status(500).json({ error: "Failed to fetch profile." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/users/attended-events
// Returns all events the logged-in user has registered for.
// ─────────────────────────────────────────────────────────────────────────────
async function getAttendedEvents(req, res) {
  try {
    // Find events where this user is in the attendees array
    const events = await Event.find({ attendees: req.user.id })
      .sort({ date: -1 })
      .populate("organizer", "username avatarUrl");

    return res.status(200).json({ events, count: events.length });
  } catch (err) {
    console.error("getAttendedEvents error:", err);
    return res.status(500).json({ error: "Failed to fetch attended events." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/users/organized-events
// Returns all events the logged-in user has created as an organizer.
// ─────────────────────────────────────────────────────────────────────────────
async function getOrganizedEvents(req, res) {
  try {
    const events = await Event.find({ organizer: req.user.id })
      .sort({ createdAt: -1 });

    return res.status(200).json({ events, count: events.length });
  } catch (err) {
    console.error("getOrganizedEvents error:", err);
    return res.status(500).json({ error: "Failed to fetch organized events." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/users/register-event/:eventId
// Register the logged-in user for an event.
// Awards +10 points and creates a confirmation notification.
// ─────────────────────────────────────────────────────────────────────────────
async function registerForEvent(req, res) {
  try {
    const event = await Event.findById(req.params.eventId);
    if (!event) return res.status(404).json({ error: "Event not found." });

    const alreadyRegistered = event.attendees.includes(req.user.id);
    if (alreadyRegistered) {
      return res.status(409).json({ error: "You are already registered for this event." });
    }

    // Add user to the event's attendees list
    event.attendees.push(req.user.id);
    await event.save();

    // Award +10 points to the user
    await User.findByIdAndUpdate(req.user.id, { $inc: { points: 10 } });

    // Auto-create a confirmation notification
    await Notification.create({
      user:  req.user.id,
      type:  "confirmation",
      title: `Registered for "${event.title}"`,
      body:  `You have successfully registered for ${event.title} on ${event.date.toDateString()}.`,
      event: event._id,
    });

    return res.status(200).json({ message: "Successfully registered for event." });
  } catch (err) {
    console.error("registerForEvent error:", err);
    return res.status(500).json({ error: "Failed to register for event." });
  }
}

module.exports = { getProfile, getAttendedEvents, getOrganizedEvents, registerForEvent };
