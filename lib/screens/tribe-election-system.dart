import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/tribe_model.dart';

class TribeLeaderElectionPage extends StatefulWidget {
  final Tribe tribe;
  
  const TribeLeaderElectionPage({super.key, required this.tribe});

  @override
  State<TribeLeaderElectionPage> createState() => _TribeLeaderElectionPageState();
}

class _TribeLeaderElectionPageState extends State<TribeLeaderElectionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  late Election currentElection;
  Candidate? selectedCandidate;
  final List<TribeLeader> currentLeaders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeElection();
  }

  Future<void> _initializeElection() async {
    try {
      final electionDoc = await _firestore
          .collection('tribes')
          .doc(widget.tribe.id)
          .collection('elections')
          .doc('current')
          .get();
      
      if (!electionDoc.exists) {
        // Create new election if none exists
        await _createNewElection();
      } else {
        final data = electionDoc.data()!;
        currentElection = Election.fromFirestore(data, electionDoc.id);
      }
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error initializing election: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _createNewElection() async {
    final now = DateTime.now();
    final electionData = {
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 3))),
      'candidates': [],
      'eligibleVoters': widget.tribe.members ?? [],
      'votesForCandidates': {},
      'vibeStatementsForCandidates': {},
      'status': 'active',
    };

    await _firestore
        .collection('tribes')
        .doc(widget.tribe.id)
        .collection('elections')
        .doc('current')
        .set(electionData);
    currentElection = Election.fromFirestore(electionData, 'current');
  }

  Future<void> _runForLeader() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final vibeStatementController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run for Tribe Leader'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Submit your vibe statement to join the election!'),
            const SizedBox(height: 16),
            TextField(
              controller: vibeStatementController,
              decoration: const InputDecoration(
                labelText: 'Vibe Statement',
                hintText: 'Describe your music style and goals...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (vibeStatementController.text.isNotEmpty) {
                try {
                  await _firestore.collection('elections').doc('current').update({
                    'candidates': FieldValue.arrayUnion([{
                      'userId': user.uid,
                      'username': user.displayName ?? 'Anonymous',
                      'profileImageUrl': user.photoURL ?? 'https://via.placeholder.com/50',
                      'contributionScore': 0, // TODO: Calculate from user activity
                      'vibeStatement': vibeStatementController.text,
                      'endorsements': 0,
                      'totalVotes': 0,
                    }]),
                    'vibeStatementsForCandidates.${user.uid}': vibeStatementController.text,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Candidacy submitted!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error submitting candidacy: $e')),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _castVote() async {
    if (selectedCandidate == null) return;

    final user = _authService.currentUser;
    if (user == null) return;

    try {
      // Check if user has already voted
      final voteDoc = await _firestore
          .collection('elections')
          .doc('current')
          .collection('votes')
          .doc(user.uid)
          .get();

      if (voteDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already voted in this election')),
        );
        return;
      }

      // Record the vote
      await _firestore.runTransaction((transaction) async {
        final electionDoc = await transaction.get(_firestore.collection('elections').doc('current'));
        
        if (!electionDoc.exists) throw Exception('Election not found');

        final data = electionDoc.data()!;
        final candidates = List<Map<String, dynamic>>.from(data['candidates'] ?? []);
        
        // Find and update the selected candidate
        final candidateIndex = candidates.indexWhere((c) => c['userId'] == selectedCandidate!.user.id);
        if (candidateIndex == -1) throw Exception('Candidate not found');

        candidates[candidateIndex]['totalVotes'] = (candidates[candidateIndex]['totalVotes'] ?? 0) + 1;
        
        transaction.update(electionDoc.reference, {'candidates': candidates});
        transaction.set(
          _firestore.collection('elections').doc('current').collection('votes').doc(user.uid),
          {
            'candidateId': selectedCandidate!.user.id,
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote cast for ${selectedCandidate!.user.name}!')),
      );

      setState(() {
        selectedCandidate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error casting vote: $e')),
      );
    }
  }

  Future<void> _endorseCandidate(Candidate candidate) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        final electionDoc = await transaction.get(_firestore.collection('elections').doc('current'));
        
        if (!electionDoc.exists) throw Exception('Election not found');

        final data = electionDoc.data()!;
        final candidates = List<Map<String, dynamic>>.from(data['candidates'] ?? []);
        
        final candidateIndex = candidates.indexWhere((c) => c['userId'] == candidate.user.id);
        if (candidateIndex == -1) throw Exception('Candidate not found');

        candidates[candidateIndex]['endorsements'] = (candidates[candidateIndex]['endorsements'] ?? 0) + 1;
        
        transaction.update(electionDoc.reference, {'candidates': candidates});
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endorsement added!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding endorsement: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tribe Leader Election'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Run for Leader',
            onPressed: _runForLeader,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('elections').doc('current').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('No election data found'));
          }

          final candidates = List<Map<String, dynamic>>.from(data['candidates'] ?? []);
          final endDate = (data['endDate'] as Timestamp).toDate();
          final now = DateTime.now();
          final isVotingOpen = now.isBefore(endDate);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vote for Your Tribe Leaders',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a candidate to view their vibe and cast your vote. Voting closes in ${endDate.difference(now).inDays} days!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final candidateData = candidates[index];
                      final candidate = Candidate(
                        user: TribeUser(
                          id: candidateData['userId'],
                          name: candidateData['username'],
                          contributionScore: candidateData['contributionScore'] ?? 0,
                        ),
                        vibeStatement: candidateData['vibeStatement'] ?? '',
                        endorsements: candidateData['endorsements'] ?? 0,
                        totalVotes: candidateData['totalVotes'] ?? 0,
                      );

                      return CandidateCard(
                        candidate: candidate,
                        isSelected: selectedCandidate?.user.id == candidate.user.id,
                        onTap: () {
                          if (isVotingOpen) {
                            setState(() {
                              selectedCandidate = candidate;
                            });
                          }
                        },
                        onEndorse: () => _endorseCandidate(candidate),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isVotingOpen && selectedCandidate != null ? _castVote : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Cast Vote'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Data models
class TribeUser {
  final String id;
  final String name;
  final int contributionScore;
  final double voteWeight;
  final bool isEligibleVoter;

  TribeUser({
    required this.id,
    required this.name,
    required this.contributionScore,
    this.voteWeight = 1.0,
    this.isEligibleVoter = true,
  });
}

class TribeLeader {
  final TribeUser user;
  double servedTimeInCurTerm;
  bool isTermCoolDown;
  int numberOfTerms;
  static const int maxDurationOfTerm = 30; // days
  static const int maxConsecutiveTerms = 2;

  TribeLeader({
    required this.user,
    this.servedTimeInCurTerm = 0,
    this.isTermCoolDown = false,
    this.numberOfTerms = 0,
  });

  bool canRunForElection() {
    return !isTermCoolDown && numberOfTerms < maxConsecutiveTerms;
  }
}

class Candidate {
  final TribeUser user;
  final String vibeStatement;
  int endorsements;
  double totalVotes;

  Candidate({
    required this.user,
    required this.vibeStatement,
    this.endorsements = 0,
    this.totalVotes = 0,
  });
}

class Election {
  final String id;
  final List<Candidate> candidates;
  final List<TribeUser> eligibleVoters;
  final Map<String, double> votesForCandidates;
  final Map<String, String> vibeStatementsForCandidates;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  static const int votingPeriodDays = 3;

  Election({
    required this.id,
    required this.candidates,
    required this.eligibleVoters,
    required this.votesForCandidates,
    required this.vibeStatementsForCandidates,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Election.fromFirestore(Map<String, dynamic> data, String id) {
    final candidates = List<Map<String, dynamic>>.from(data['candidates'] ?? [])
        .map((c) => Candidate(
              user: TribeUser(
                id: c['userId'],
                name: c['username'],
                contributionScore: c['contributionScore'] ?? 0,
              ),
              vibeStatement: c['vibeStatement'] ?? '',
              endorsements: c['endorsements'] ?? 0,
              totalVotes: c['totalVotes'] ?? 0,
            ))
        .toList();

    final eligibleVoters = List<Map<String, dynamic>>.from(data['eligibleVoters'] ?? [])
        .map((v) => TribeUser(
              id: v['userId'],
              name: v['username'],
              contributionScore: v['contributionScore'] ?? 0,
            ))
        .toList();

    return Election(
      id: id,
      candidates: candidates,
      eligibleVoters: eligibleVoters,
      votesForCandidates: Map<String, double>.from(data['votesForCandidates'] ?? {}),
      vibeStatementsForCandidates: Map<String, String>.from(data['vibeStatementsForCandidates'] ?? {}),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
    );
  }

  bool isVotingOpen() {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate) && status == 'active';
  }

  List<Candidate> getTop3Winners() {
    final sortedCandidates = List<Candidate>.from(candidates)
      ..sort((a, b) => b.totalVotes.compareTo(a.totalVotes));
    return sortedCandidates.take(3).toList();
  }
}

// Widget for displaying candidate information
class CandidateCard extends StatelessWidget {
  final Candidate candidate;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEndorse;

  const CandidateCard({
    super.key,
    required this.candidate,
    required this.isSelected,
    required this.onTap,
    required this.onEndorse,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    candidate.user.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Score: ${candidate.user.contributionScore}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                candidate.vibeStatement,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${candidate.endorsements} Endorsements',
                    style: const TextStyle(color: Colors.blue),
                  ),
                  TextButton(
                    onPressed: onEndorse,
                    child: const Text('Endorse'),
                  ),
                ],
              ),
              if (candidate.totalVotes > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Votes: ${candidate.totalVotes.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}