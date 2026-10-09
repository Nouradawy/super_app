import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/src/models/reaction.dart';

/// A controller class to manage message reactions.
///
/// This controller handles adding, removing, and toggling reactions for messages,
/// and notifies listeners when the reaction state changes.
class ReactionsController extends ChangeNotifier {
  /// A map to store reactions for each message ID.
  final Map<String, List<Reaction>> _messageReactions = {};

  /// The ID of the current user.
  String _currentUserId;
  String get currentUserId => _currentUserId;

  /// Updates the current user ID if it changes during auth lifecycle.
  void updateCurrentUserId(String newUserId) {
    if (_currentUserId != newUserId && newUserId.isNotEmpty) {
      _currentUserId = newUserId;
      notifyListeners();
    }
  }

  /// Creates a reactions controller.
  ///
  /// The [currentUserId] is required to identify the user's reactions.
  ReactionsController({required String currentUserId}) : _currentUserId = currentUserId;

  /// Normalizes an emoji to standard Unicode representation without variation selector 16 (\uFE0F)
  /// and maps synonymous emojis to Telegram standard reactions (e.g. 😮 -> 😱, 😠 -> 😡).
  static String normalizeEmoji(String emoji) {
    if (emoji.isEmpty) return emoji;
    var cleaned = emoji.replaceAll('\uFE0F', '');
    if (cleaned == '😮') cleaned = '😱';
    if (cleaned == '😠') cleaned = '😡';
    return cleaned;
  }

  /// Retrieves the list of reactions for a given [messageId].
  List<Reaction> getReactions(String messageId) {
    return _messageReactions[messageId] ?? [];
  }

  /// Returns a map of reaction counts for a given [messageId].
  Map<String, int> getReactionCounts(String messageId) {
    final reactions = getReactions(messageId);
    final counts = <String, int>{};
    for (final reaction in reactions) {
      final norm = normalizeEmoji(reaction.emoji);
      counts[norm] = (counts[norm] ?? 0) + 1;
    }
    return counts;
  }

  /// Checks if the current user has reacted with a specific [emoji] to a [messageId].
  bool hasUserReacted(String messageId, String emoji, {String? userId, String? tgUserId}) {
    final norm = normalizeEmoji(emoji);
    final reactions = getReactions(messageId);
    final uid = (userId ?? currentUserId).trim();
    final tg = tgUserId?.trim();
    return reactions.any((r) {
      if (normalizeEmoji(r.emoji) != norm) return false;
      final rId = r.userId.trim();
      return rId == uid ||
          rId == 'self' ||
          (tg != null && tg.isNotEmpty && rId == tg) ||
          (currentUserId.isNotEmpty && rId == currentUserId);
    });
  }

  /// Returns the emoji the current user has reacted with for [messageId], if any.
  String? getUserReaction(String messageId, {String? userId, String? tgUserId}) {
    final reactions = getReactions(messageId);
    final uid = (userId ?? currentUserId).trim();
    final tg = tgUserId?.trim();
    for (final r in reactions) {
      final rId = r.userId.trim();
      if (rId == uid ||
          rId == 'self' ||
          (tg != null && tg.isNotEmpty && rId == tg) ||
          (currentUserId.isNotEmpty && rId == currentUserId)) {
        return normalizeEmoji(r.emoji);
      }
    }
    return null;
  }

  /// Adds a reaction with the given [emoji] to a [messageId].
  ///
  /// An optional [userName] can be provided.
  void addReaction(String messageId, String emoji, {String? userName}) {
    final norm = normalizeEmoji(emoji);
    final reactions = _messageReactions[messageId] ?? [];
    final existingIndex = reactions.indexWhere(
      (r) => normalizeEmoji(r.emoji) == norm && r.userId == currentUserId,
    );

    if (existingIndex == -1) {
      reactions.add(Reaction(
        emoji: norm,
        userId: currentUserId,
        timestamp: DateTime.now(),
        userName: userName,
      ));
      _messageReactions[messageId] = reactions;
      notifyListeners();
    }
  }

  /// Removes a reaction with the given [emoji] from a [messageId].
  void removeReaction(String messageId, String emoji) {
    final norm = normalizeEmoji(emoji);
    final reactions = _messageReactions[messageId] ?? [];
    reactions.removeWhere(
      (r) => normalizeEmoji(r.emoji) == norm && r.userId == currentUserId,
    );
    _messageReactions[messageId] = reactions;
    notifyListeners();
  }

  /// Toggles a reaction with the given [emoji] for a [messageId].
  ///
  /// If the user has already reacted with the emoji, it's removed. Otherwise, it's added.
  void toggleReaction(String messageId, String emoji, {String? userName}) {
    final norm = normalizeEmoji(emoji);
    final reactions = _messageReactions[messageId] ?? [];
    final userReactionIndex =
        reactions.indexWhere((r) => r.userId == currentUserId);

    if (userReactionIndex != -1) {
      final existingReaction = reactions[userReactionIndex];
      // If the user is selecting the same reaction, remove it.
      if (normalizeEmoji(existingReaction.emoji) == norm) {
        removeReaction(messageId, norm);
      } else {
        // If the user is selecting a different reaction, replace the old one.
        reactions.removeAt(userReactionIndex);
        addReaction(messageId, norm, userName: userName);
      }
    } else {
      // If the user has no reaction, add the new one.
      addReaction(messageId, norm, userName: userName);
    }
  }

  /// Clears all reactions for a specific [messageId].
  void clearReactions(String messageId) {
    _messageReactions.remove(messageId);
    notifyListeners();
  }

  /// Clears all reactions for all messages.
  void clearAllReactions() {
    _messageReactions.clear();
    notifyListeners();
  }

  /// Loads a list of [reactions] for a given [messageId] from an external source.
  void loadReactions(String messageId, List<Reaction> reactions) {
    _messageReactions[messageId] = reactions
        .map((r) => Reaction(
              emoji: normalizeEmoji(r.emoji),
              userId: r.userId,
              timestamp: r.timestamp,
              userName: r.userName,
            ))
        .toList();
    notifyListeners();
  }

  /// Loads reactions for multiple messages at once and fires [notifyListeners]
  /// only a single time.
  ///
  /// Prefer this over calling [loadReactions] in a loop to avoid scheduling a
  /// separate rebuild for every message, which can conflict with an in-progress
  /// [SliverAnimatedList] animation and cause assertion errors.
  void loadAllReactions(Map<String, List<Reaction>> allReactions) {
    allReactions.forEach((msgId, list) {
      _messageReactions[msgId] = list
          .map((r) => Reaction(
                emoji: normalizeEmoji(r.emoji),
                userId: r.userId,
                timestamp: r.timestamp,
                userName: r.userName,
              ))
          .toList();
    });
    notifyListeners();
  }

  /// Returns an unmodifiable map of all reactions for persistence.
  Map<String, List<Reaction>> getAllReactions() {
    return Map.unmodifiable(_messageReactions);
  }
}
