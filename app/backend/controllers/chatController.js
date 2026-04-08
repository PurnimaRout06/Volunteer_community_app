// controllers/chatController.js
// ─────────────────────────────────────────────────────────────────────────────
// Handles the Chat tab.
// ─────────────────────────────────────────────────────────────────────────────

const { Chat, Message } = require("../models/Chat");

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/chats
// Returns all chat threads for the logged-in user with last message preview.
// ─────────────────────────────────────────────────────────────────────────────
async function getChatList(req, res) {
  try {
    const userId = req.user.id;

    // Find all chats where the user is either the attendee or the organizer
    const chats = await Chat.find({
      $or: [{ user: userId }, { organizer: userId }],
    })
      .sort({ lastMessageAt: -1 })
      .populate("user",      "username avatarUrl")
      .populate("organizer", "username avatarUrl")
      .populate("event",     "title");

    return res.status(200).json({ chats });
  } catch (err) {
    console.error("getChatList error:", err);
    return res.status(500).json({ error: "Failed to fetch chat list." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/chats/:chatId/messages
// Returns all messages in a chat thread (oldest first).
// ─────────────────────────────────────────────────────────────────────────────
async function getMessages(req, res) {
  try {
    const userId = req.user.id;
    const { chatId } = req.params;

    // Security: confirm the requesting user is part of this chat
    const chat = await Chat.findOne({
      _id: chatId,
      $or: [{ user: userId }, { organizer: userId }],
    });
    if (!chat) return res.status(404).json({ error: "Chat not found or access denied." });

    const messages = await Message.find({ chat: chatId })
      .sort({ createdAt: 1 })
      .populate("sender", "username avatarUrl");

    return res.status(200).json({ messages });
  } catch (err) {
    console.error("getMessages error:", err);
    return res.status(500).json({ error: "Failed to fetch messages." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/chats/:chatId/messages
// Send a message in an existing chat thread.
// Body: { content }
// ─────────────────────────────────────────────────────────────────────────────
async function sendMessage(req, res) {
  try {
    const userId = req.user.id;
    const { chatId } = req.params;
    const { content } = req.body;

    if (!content || content.trim() === "") {
      return res.status(400).json({ error: "Message content cannot be empty." });
    }

    // Security: confirm the user is part of this chat before posting
    const chat = await Chat.findOne({
      _id: chatId,
      $or: [{ user: userId }, { organizer: userId }],
    });
    if (!chat) return res.status(404).json({ error: "Chat not found or access denied." });

    const message = await Message.create({
      chat:    chatId,
      sender:  userId,
      content: content.trim(),
    });

    // Update the chat's last message cache for the chat list preview
    chat.lastMessage   = content.trim();
    chat.lastMessageAt = new Date();
    await chat.save();

    const populated = await message.populate("sender", "username avatarUrl");
    return res.status(201).json({ message: "Message sent.", data: populated });
  } catch (err) {
    console.error("sendMessage error:", err);
    return res.status(500).json({ error: "Failed to send message." });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/chats
// Start a new chat thread between the user and an organizer.
// Body: { organizerId, eventId (optional) }
// ─────────────────────────────────────────────────────────────────────────────
async function startChat(req, res) {
  try {
    const userId = req.user.id;
    const { organizerId, eventId } = req.body;

    if (!organizerId) return res.status(400).json({ error: "organizerId is required." });
    if (userId === organizerId) return res.status(400).json({ error: "You cannot chat with yourself." });

    // Reuse an existing thread if one already exists for this pair + event
    const filter = { user: userId, organizer: organizerId };
    if (eventId) filter.event = eventId;

    let chat = await Chat.findOne(filter);

    if (chat) {
      return res.status(200).json({ message: "Chat already exists.", chat });
    }

    chat = await Chat.create({ user: userId, organizer: organizerId, event: eventId || null });
    return res.status(201).json({ message: "Chat started.", chat });
  } catch (err) {
    console.error("startChat error:", err);
    return res.status(500).json({ error: "Failed to start chat." });
  }
}

module.exports = { getChatList, getMessages, sendMessage, startChat };
