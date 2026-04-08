// controllers/eventController.js
// ─────────────────────────────────────────────────────────────────────────────
// Handles all event-related API logic:
// - Search & filter events  (Search tab)
// - Get upcoming events     (Search tab)
// - Get featured event      (Home tab)
// - Create / edit / delete  (Home tab — organizers)
// ─────────────────────────────────────────────────────────────────────────────

const Event = require("../models/Event");

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/events/upcoming
// Returns all future events sorted by date ascending (soonest first).
// ─────────────────────────────────────────────────────────────────────────────
async function getUpcomingEvents(req, res) {
  try {
    const events = await Event.find({ date: { $gte: new Date() } })
      .sort({ date: 1 })
      .populate("organizer", "username avatarUrl"); // Join organizer details

    return res.status(200).json({ events });
  } catch (err) {
    console.error("getUpcomingEvents error:", err);
    return res.status(500).json({ error: "Failed to fetch upcoming events." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/events/search
// Search events by keyword and filter by location, category, date.
// Query params: q, location, category, date (YYYY-MM-DD)
// ─────────────────────────────────────────────────────────────────────────────
async function searchEvents(req, res) {
  try {
    const { q, location, category, date } = req.query;

    // Build a Mongoose filter object dynamically
    const filter = {};

    // Keyword search — case-insensitive regex on title and description
    if (q) {
      filter.$or = [
        { title:       { $regex: q, $options: "i" } },
        { description: { $regex: q, $options: "i" } },
      ];
    }

    if (location) filter.location = { $regex: location, $options: "i" };
    if (category) filter.category = category;

    // Date filter — match all events on the given day
    if (date) {
      const start = new Date(date);
      const end   = new Date(date);
      end.setDate(end.getDate() + 1);
      filter.date = { $gte: start, $lt: end };
    }

    const events = await Event.find(filter)
      .sort({ date: 1 })
      .populate("organizer", "username avatarUrl");

    return res.status(200).json({ events, count: events.length });
  } catch (err) {
    console.error("searchEvents error:", err);
    return res.status(500).json({ error: "Failed to search events." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/events/featured
// Returns the featured event for the Home tab.
// ─────────────────────────────────────────────────────────────────────────────
async function getFeaturedEvent(req, res) {
  try {
    const event = await Event.findOne({ isFeatured: true })
      .sort({ date: 1 })
      .populate("organizer", "username avatarUrl");

    if (!event) return res.status(404).json({ error: "No featured event found." });
    return res.status(200).json({ event });
  } catch (err) {
    console.error("getFeaturedEvent error:", err);
    return res.status(500).json({ error: "Failed to fetch featured event." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/events/:id
// Full details for a single event.
// ─────────────────────────────────────────────────────────────────────────────
async function getEventById(req, res) {
  try {
    const event = await Event.findById(req.params.id)
      .populate("organizer", "username avatarUrl")
      .populate("attendees", "username avatarUrl");

    if (!event) return res.status(404).json({ error: "Event not found." });
    return res.status(200).json({ event });
  } catch (err) {
    console.error("getEventById error:", err);
    return res.status(500).json({ error: "Failed to fetch event." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/events
// Create a new event. The logged-in user becomes the organizer.
// ─────────────────────────────────────────────────────────────────────────────
async function createEvent(req, res) {
  try {
    const { title, description, category, location, date, time, imageUrl, isFeatured } = req.body;

    if (!title || !date) {
      return res.status(400).json({ error: "title and date are required." });
    }

    const event = await Event.create({
      title,
      description,
      category,
      location,
      date: new Date(date),
      time,
      imageUrl,
      isFeatured: isFeatured || false,
      organizer: req.user.id,   // From the JWT payload
    });

    return res.status(201).json({ message: "Event created successfully.", event });
  } catch (err) {
    console.error("createEvent error:", err);
    return res.status(500).json({ error: "Failed to create event." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PUT /api/events/:id
// Edit an event. Only the organizer who created it can edit.
// ─────────────────────────────────────────────────────────────────────────────
async function editEvent(req, res) {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) return res.status(404).json({ error: "Event not found." });

    // Authorization: only the organizer can edit
    if (event.organizer.toString() !== req.user.id) {
      return res.status(403).json({ error: "You are not authorized to edit this event." });
    }

    // Update only provided fields
    const fields = ["title", "description", "category", "location", "time", "imageUrl", "isFeatured"];
    fields.forEach((field) => {
      if (req.body[field] !== undefined) event[field] = req.body[field];
    });

    // Handle date separately — convert string to Date object
    if (req.body.date) event.date = new Date(req.body.date);

    await event.save();
    return res.status(200).json({ message: "Event updated successfully.", event });
  } catch (err) {
    console.error("editEvent error:", err);
    return res.status(500).json({ error: "Failed to update event." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/events/:id
// Delete an event. Only the organizer can delete.
// ─────────────────────────────────────────────────────────────────────────────
async function deleteEvent(req, res) {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) return res.status(404).json({ error: "Event not found." });

    if (event.organizer.toString() !== req.user.id) {
      return res.status(403).json({ error: "You are not authorized to delete this event." });
    }

    await event.deleteOne();
    return res.status(200).json({ message: "Event deleted successfully." });
  } catch (err) {
    console.error("deleteEvent error:", err);
    return res.status(500).json({ error: "Failed to delete event." });
  }
}

module.exports = {
  getUpcomingEvents,
  searchEvents,
  getFeaturedEvent,
  getEventById,
  createEvent,
  editEvent,
  deleteEvent,
};
