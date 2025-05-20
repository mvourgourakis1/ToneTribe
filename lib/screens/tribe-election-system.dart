import 'package:flutter/material.dart';

void main() {
  runApp(const TribeLeaderElectionApp());
}

class TribeLeaderElectionApp extends StatelessWidget {
  const TribeLeaderElectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tribe Leader Election',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TribeLeaderElectionPage(),
    );
  }
}

class TribeLeaderElectionPage extends StatefulWidget {
  const TribeLeaderElectionPage({super.key});

  @override
  State<TribeLeaderElectionPage> createState() => _TribeLeaderElectionPageState();
}

class _TribeLeaderElectionPageState extends State<TribeLeaderElectionPage> {
  // Mock data simulating the Election class
  final List<Candidate> candidates = [
    Candidate(
      user: TribeUser(id: 1, name: 'DJ Vibe', contributionScore: 85),
      vibeStatement: 'Bringing chill lo-fi and upbeat EDM to keep the Tribe grooving!',
      endorsements: 12,
    ),
    Candidate(
      user: TribeUser(id: 2, name: 'Melody Maven', contributionScore: 78),
      vibeStatement: 'Curating soulful R&B and indie pop for a vibey TribeList.',
      endorsements: 9,
    ),
    Candidate(
      user: TribeUser(id: 3, name: 'Bass Boss', contributionScore: 92),
      vibeStatement: 'Heavy basslines and trap beats to energize the Tribe!',
      endorsements: 15,
    ),
  ];

  // Track selected candidate for voting
  Candidate? selectedCandidate;

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vote for Your Tribe Leaders',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a candidate to view their vibe and cast your vote. Voting closes in 3 days!',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final candidate = candidates[index];
                  return CandidateCard(
                    candidate: candidate,
                    isSelected: selectedCandidate == candidate,
                    onTap: () {
                      setState(() {
                        selectedCandidate = candidate;
                      });
                    },
                    onEndorse: () {
                      setState(() {
                        candidate.endorsements++;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: selectedCandidate != null ? _castVote : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Cast Vote'),
            ),
          ],
        ),
      ),
    );
  }

  void _runForLeader() {
    // Simulate running for leader
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run for Tribe Leader'),
        content: const Text('Submit your vibe statement to join the election!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement runForLeader logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Candidacy submitted!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _castVote() {
    // Simulate casting a vote
    if (selectedCandidate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote cast for ${selectedCandidate!.user.name}!')),
      );
      // TODO: Implement voteFor logic with weighted voting
    }
  }
}

// Data models
class TribeUser {
  final int id;
  final String name;
  final int contributionScore;

  TribeUser({required this.id, required this.name, required this.contributionScore});
}

class Candidate {
  final TribeUser user;
  final String vibeStatement;
  int endorsements;

  Candidate({
    required this.user,
    required this.vibeStatement,
    required this.endorsements,
  });
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
            ],
          ),
        ),
      ),
    );
  }
}