import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Read-only social features. Economic state is deliberately never edited here.
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key, this.firebaseReady = true});

  final bool firebaseReady;

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _uidController = TextEditingController();
  bool _adding = false;
  String? _message;
  String _leaderboardSort = 'level';
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _tabs.dispose();
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _addFriend() async {
    final uid = _uid;
    final friendUid = _uidController.text.trim();
    if (uid == null) { setState(() => _message = 'سجّل الدخول أولاً لإضافة الأصدقاء.'); return; }
    if (friendUid.isEmpty || friendUid == uid) { setState(() => _message = 'أدخل معرّف لاعب صحيحاً ومختلفاً عن معرّفك.'); return; }
    setState(() { _adding = true; _message = null; });
    try {
      final db = FirebaseFirestore.instance;
      final friend = await db.collection('publicProfiles').doc(friendUid).get();
      if (!friend.exists) {
        setState(() => _message = 'لم يتم العثور على لاعب بهذا المعرّف.');
      } else {
        await db.collection('users').doc(uid).collection('friends').doc(friendUid).set({
          'uid': friendUid,
          'addedAt': FieldValue.serverTimestamp(),
        });
        _uidController.clear();
        setState(() => _message = 'تمت إضافة اللاعب إلى قائمة أصدقائك.');
      }
    } catch (_) {
      setState(() => _message = 'تعذرت إضافة الصديق. تحقق من الاتصال وقواعد أمان Firebase.');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseReady) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: 58)),
              SizedBox(height: 12),
              Text('المنافسات الجماعية', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text(
                'لوحة الشرف والأصدقاء وزيارة المزارع تحتاج اتصال Firebase. اللعبة المحلية جاهزة، ونفعّل هذه المزايا بالمرحلة الأخيرة.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_uid == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('سجّل الدخول لاستخدام لوحة الشرف والأصدقاء.')));
    }
    return Column(children: [
      Material(
        color: Theme.of(context).colorScheme.surface,
        child: TabBar(controller: _tabs, tabs: const [Tab(text: '🏆 لوحة الشرف'), Tab(text: '🤝 أصدقائي')]),
      ),
      Expanded(child: TabBarView(controller: _tabs, children: [_leaderboard(), _friends()])),
    ]);
  }

  Widget _leaderboard() => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(children: [
        const Expanded(child: Text('ترتيب المزارعين', style: TextStyle(fontWeight: FontWeight.w900))),
        DropdownButton<String>(
          value: _leaderboardSort,
          items: const [
            DropdownMenuItem(value: 'level', child: Text('حسب المستوى')),
            DropdownMenuItem(value: 'money', child: Text('حسب الثروة')),
          ],
          onChanged: (value) { if (value != null) setState(() => _leaderboardSort = value); },
        ),
      ]),
    ),
    Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('publicProfiles').orderBy(_leaderboardSort, descending: true).limit(100).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('تعذر تحميل لوحة الشرف. راجع قواعد Firebase.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs.toList();
      docs.sort((a, b) {
        final primary = ((b.data()[_leaderboardSort] as num?) ?? 0).compareTo((a.data()[_leaderboardSort] as num?) ?? 0);
        if (primary != 0) return primary;
        return ((b.data()[_leaderboardSort == 'level' ? 'money' : 'level'] as num?) ?? 0).compareTo((a.data()[_leaderboardSort == 'level' ? 'money' : 'level'] as num?) ?? 0);
      });
      if (docs.isEmpty) return const Center(child: Text('لا يوجد لاعبون في لوحة الشرف حتى الآن.'));
      return ListView.builder(itemCount: docs.length, itemBuilder: (context, index) {
        final data = docs[index].data();
        final isMe = docs[index].id == _uid;
        return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: ListTile(
          leading: CircleAvatar(child: Text(index < 3 ? ['🥇', '🥈', '🥉'][index] : '${index + 1}')),
          title: Text('${(data['name'] as String?)?.trim().isNotEmpty == true ? data['name'] : 'مزارع'}${isMe ? ' (أنت)' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('المستوى ${((data['level'] as num?) ?? 1).toInt()}'),
          trailing: Text('${_formatMoney(((data['money'] as num?) ?? 0).toInt())} د.ع', style: const TextStyle(fontWeight: FontWeight.bold)),
        ));
      });
    },
  )),
  ]);

  Widget _friends() => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 4), child: Row(children: [
      Expanded(child: TextField(controller: _uidController, decoration: const InputDecoration(labelText: 'معرّف اللاعب (UID)', hintText: 'الصق معرّف صديقك', border: OutlineInputBorder()), textInputAction: TextInputAction.done, onSubmitted: (_) => _addFriend())),
      const SizedBox(width: 8),
      FilledButton(onPressed: _adding ? null : _addFriend, child: _adding ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('إضافة')),
    ])),
    if (_message != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.primary))),
    const Padding(padding: EdgeInsets.all(8), child: Text('المزارع المعروضة للزيارة للعرض فقط؛ لا توجد تحويلات أموال بين اللاعبين.')),
    Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(_uid).collection('friends').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الأصدقاء. راجع قواعد Firebase.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text('لم تضف أصدقاء بعد. أضف صديقاً باستخدام UID الخاص به.'));
        return ListView(children: snapshot.data!.docs.map((friendDoc) => _friendTile(friendDoc.id)).toList());
      },
    )),
  ]);

  Widget _friendTile(String friendUid) => FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    future: FirebaseFirestore.instance.collection('publicProfiles').doc(friendUid).get(),
    builder: (context, snapshot) {
      final data = snapshot.data?.data();
      return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: ListTile(
        leading: const CircleAvatar(child: Text('🌾')),
        title: Text(data?['name'] as String? ?? 'مزارع'),
        subtitle: Text('المستوى ${((data?['level'] as num?) ?? 1).toInt()} • UID: $friendUid', maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: IconButton(tooltip: 'حذف الصديق', icon: const Icon(Icons.person_remove_alt_1), onPressed: () async {
          try { await FirebaseFirestore.instance.collection('users').doc(_uid).collection('friends').doc(friendUid).delete(); }
          catch (_) { if (mounted) setState(() => _message = 'تعذر حذف الصديق.'); }
        }),
        onTap: () => _showFarmVisit(data),
      ));
    },
  );


  Future<void> _showFarmVisit(Map<String, dynamic>? profile) async {
    if (!mounted) return;
    final rawPlots = profile?['farmPlots'];
    final plots = rawPlots is List ? rawPlots.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    final name = profile?['name'] as String? ?? 'مزرعة صديق';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('زيارة $name'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المستوى: ${((profile?['level'] as num?) ?? 1).toInt()}'),
              const SizedBox(height: 12),
              const Text('مزرعة الصديق — عرض فقط', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (plots.isEmpty)
                const Text('لم يشارك هذا اللاعب لقطة مزرعته بعد. افتح اللعبة لديه واتصل بالإنترنت لتحديثها.')
              else
                Flexible(
                  child: SizedBox(
                    height: 260,
                    child: GridView.builder(
                      shrinkWrap: true,
                      itemCount: plots.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6,
                      ),
                      itemBuilder: (context, index) {
                        final plot = plots[index];
                        final cropId = plot['cropId'] as String?;
                        final plantedAt = DateTime.tryParse(plot['plantedAt'] as String? ?? '');
                        final seconds = (plot['growSeconds'] as num?)?.toInt() ?? 0;
                        final ready = cropId != null && plantedAt != null &&
                            !DateTime.now().isBefore(plantedAt.add(Duration(seconds: seconds)));
                        return Container(
                          decoration: BoxDecoration(
                            color: cropId == null ? Colors.brown.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cropId == null ? '🟫' : (ready ? '🌾' : '🌱'), style: const TextStyle(fontSize: 26)),
                              Text(cropId == null ? 'فارغة' : (ready ? 'جاهز' : 'ينمو'),
                                style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text('لا يمكنك الحصاد أو الشراء أو تغيير بيانات مزرعة صديقك.'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
      ),
    );
  }

  String _formatMoney(int amount) => amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}
