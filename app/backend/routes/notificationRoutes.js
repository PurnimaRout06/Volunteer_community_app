// routes/notificationRoutes.js
const express = require("express");
const router = express.Router();
const { getNotifications, markAsRead, markAllAsRead, sendEventNotification } = require("../controllers/notificationController");
const { authenticateToken } = require("../middleware/auth");

router.use(authenticateToken);

// GET   /api/notifications              — Get all notifications for the user
router.get("/", getNotifications);

// PATCH /api/notifications/read-all     — Mark all as read
router.patch("/read-all", markAllAsRead);

// PATCH /api/notifications/:id/read     — Mark one as read
router.patch("/:id/read", markAsRead);

// POST  /api/notifications/send         — Organizer sends update to all attendees
router.post("/send", sendEventNotification);

module.exports = router;
