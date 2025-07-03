import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BlockedPlayers extends ChangeNotifier {
  BlockedPlayers();
  
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final Map<String, String> _blockedPlayers = <String, String>{};
  Map<String, String> get blockedPlayers => _blockedPlayers;
  
  String? get currentUserUid => _auth.currentUser?.uid;
  
  // Add a player to blocked list (flag them)
  Future<void> add(String targetPlayerUid, String playerName) async {
    if (currentUserUid == null) return;
    
    try {
      // Write to stats/{targetPlayerUid}/flagged/{currentUserUid}: playerName
      await _database
          .child('stats')
          .child(targetPlayerUid)
          .child('flagged')
          .child(currentUserUid!)
          .set(playerName);
      
      // Update local map
      _blockedPlayers[targetPlayerUid] = playerName;
      notifyListeners();
    } catch (e) {
      print('Error adding blocked player: $e');
    }
  }
  
  // Remove a player from blocked list (unflag them)
  Future<void> remove(String targetPlayerUid) async {
    if (currentUserUid == null) return;
    
    try {
      // Remove from stats/{targetPlayerUid}/flagged/{currentUserUid}
      await _database
          .child('stats')
          .child(targetPlayerUid)
          .child('flagged')
          .child(currentUserUid!)
          .remove();
      
      // Update local map
      _blockedPlayers.remove(targetPlayerUid);
      notifyListeners();
    } catch (e) {
      print('Error removing blocked player: $e');
    }
  }
  
  // Load all players that current user has flagged
  Future<void> loadBlockedPlayers() async {
    if (currentUserUid == null) return;
    
    try {
      _blockedPlayers.clear();
      
      // Get all stats entries
      final snapshot = await _database.child('stats').once();
      
      if (snapshot.snapshot.value != null) {
        final Map<dynamic, dynamic> stats = snapshot.snapshot.value as Map<dynamic, dynamic>;
        
        // Check each player's flagged collection for current user's entry
        stats.forEach((playerUid, playerData) {
          if (playerData is Map && playerData.containsKey('flagged')) {
            final Map<dynamic, dynamic> flagged = playerData['flagged'] as Map<dynamic, dynamic>;
            
            // If current user has flagged this player
            if (flagged.containsKey(currentUserUid)) {
              _blockedPlayers[playerUid.toString()] = flagged[currentUserUid].toString();
            }
          }
        });
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading blocked players: $e');
    }
  }
  
  // Check if a specific player is blocked
  bool isBlocked(String playerUid) {
    return _blockedPlayers.containsKey(playerUid);
  }
  
  // Initialize - call this when the user logs in
  Future<void> initialize() async {
    await loadBlockedPlayers();
  }
}