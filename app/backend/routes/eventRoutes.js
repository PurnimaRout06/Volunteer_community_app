// routes/eventRoutes.js
const express = require("express");
const router = express.Router();
const {
  getUpcomingEvents,
  searchEvents,
  getFeaturedEvent,
  getEventById,
  createEvent,
  editEvent,
  deleteEvent,
} = require("../controllers/eventController");
const { authenticateToken } = require("../middleware/auth");

// All event routes require the user to be logged in
router.use(authenticateToken);

// GET /api/events/upcoming          — Get upcoming events (Search tab)
router.get("/upcoming", getUpcomingEvents);

// GET /api/events/search?q=&location=&category=&date= — Search & filter (Search tab)
router.get("/search", searchEvents);

// GET /api/events/featured           — Get featured event (Home tab)
router.get("/featured", getFeaturedEvent);

// GET /api/events/:id                — Get a single event's details
router.get("/:id", getEventById);

// POST /api/events                   — Create a new event (Home tab)
router.post("/", createEvent);

// PUT /api/events/:id                — Edit an event (organizer only)
router.put("/:id", editEvent);

// DELETE /api/events/:id             — Delete an event (organizer only)
router.delete("/:id", deleteEvent);

module.exports = router;
