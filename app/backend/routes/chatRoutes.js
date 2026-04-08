// routes/chatRoutes.js
const express = require("express");
const router = express.Router();
const { getChatList, getMessages, sendMessage, startChat } = require("../controllers/chatController");
const { authenticateToken } = require("../middleware/auth");

router.use(authenticateToken);

// GET  /api/chats                        — Get all chat threads for the user
router.get("/", getChatList);

// POST /api/chats                        — Start a new chat with an organizer
router.post("/", startChat);

// GET  /api/chats/:chatId/messages       — Get all messages in a chat
router.get("/:chatId/messages", getMessages);

// POST /api/chats/:chatId/messages       — Send a message in a chat
router.post("/:chatId/messages", sendMessage);

module.exports = router;
