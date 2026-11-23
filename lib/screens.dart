import 'package:material_ui/material_ui.dart';

import 'domain.dart';

const ink = Color(0xff24445a);
const artPath = 'assets/website/';
Widget artwork(String name, [double size = 40]) => Image.asset(
  '$artPath$name.png',
  width: size,
  height: size,
  fit: BoxFit.contain,
  excludeFromSemantics: true,
);
Widget heading(String text) => Text(
  text,
  style: const TextStyle(
    fontSize: 25,
    height: 1.5,
    fontWeight: FontWeight.w700,
    color: ink,
  ),
);
Widget body(String text) => Text(
  text,
  style: const TextStyle(fontSize: 16, height: 1.7, color: Color(0xff3d5f76)),
);
Widget panel(List<Widget> children) => Material(
  color: const Color(0xf2f2f9ff),
  clipBehavior: Clip.antiAlias,
  shape: RoundedRectangleBorder(
    side: const BorderSide(color: Color(0xffbfd8e9)),
    borderRadius: BorderRadius.circular(19),
  ),
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spaced(children, 12),
    ),
  ),
);
List<Widget> spaced(List<Widget> children, [double gap = 18]) => [
  for (var i = 0; i < children.length; i++) ...[
    if (i > 0) SizedBox(height: gap),
    children[i],
  ],
];
Widget pageContent(List<Widget> children) => ListView(
  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
  children: [
    Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: spaced([
            const Text(
              '開發示範 · 未連接正式服務',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xff466b84)),
            ),
            ...children,
          ]),
        ),
      ),
    ),
  ],
);

class OceanBackground extends StatelessWidget {
  const OceanBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: ColoredBox(color: Color(0xffdfeffb))),
      Positioned(
        top: 0,
        right: 0,
        width: 800,
        height: 450,
        child: Opacity(
          opacity: .6,
          child: Image.asset(
            '${artPath}ocean_watercolor_chibi_background.png',
            fit: BoxFit.fill,
            excludeFromSemantics: true,
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        width: 800,
        height: 450,
        child: Opacity(
          opacity: .65,
          child: Image.asset(
            '${artPath}ocean_watercolor_chibi_background.png',
            fit: BoxFit.fill,
            excludeFromSemantics: true,
          ),
        ),
      ),
      Positioned.fill(child: SafeArea(top: false, child: child)),
    ],
  );
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: OceanBackground(child: child),
  );
}

void openPage(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: OceanBackground(
      child: SafeArea(
        child: pageContent([
          const SizedBox(height: 24),
          Center(child: artwork('aquaculture_fish_favicon_v1', 110)),
          heading('養殖漁業知識平台'),
          body('把問答、引用來源與自己的筆記，帶到每一次養殖觀察中。'),
          panel([body('此安裝版目前提供開發示範，所有回答與來源均為占位資料。此版本不收集真實帳號密碼。')]),
          FilledButton(onPressed: store.login, child: const Text('進入示範帳號')),
          body('示範資料只保留在本次使用期間，登出或關閉程式後會清除。'),
        ]),
      ),
    ),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.store});
  final AppStore store;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0, seed = 0;
  String question = '', fish = '全部魚種';
  void ask([String q = '', String f = '全部魚種']) => setState(() {
    question = q;
    fish = f;
    seed++;
    tab = 1;
  });
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: tab == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && tab != 0) setState(() => tab = 0);
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          ['養殖漁業知識平台', '知識問答', '我的收藏', '我的'][tab],
          style: const TextStyle(fontSize: 20),
        ),
      ),
      body: OceanBackground(
        child: IndexedStack(
          index: tab,
          children: [
            HomeScreen(onAsk: ask),
            AskScreen(
              key: ValueKey(seed),
              store: widget.store,
              question: question,
              species: fish,
            ),
            SavedScreen(store: widget.store),
            MeScreen(store: widget.store),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: [
          NavigationDestination(
            icon: artwork('aquaculture_fish_favicon_v1', 32),
            label: '首頁',
          ),
          NavigationDestination(
            icon: artwork('watercolor_chat', 32),
            label: '問答',
          ),
          NavigationDestination(
            icon: artwork('watercolor_knowledge', 32),
            label: '收藏',
          ),
          NavigationDestination(
            icon: artwork('watercolor_history', 32),
            label: '我的',
          ),
        ],
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onAsk});
  final void Function([String, String]) onAsk;
  @override
  Widget build(BuildContext context) => pageContent([
    body('你好，養殖夥伴'),
    heading('今天想了解什麼？'),
    panel([
      artwork('watercolor_chat', 70),
      heading('從一個問題開始。'),
      body('找到有來源的知識，留下自己的觀察。'),
      FilledButton(onPressed: onAsk, child: const Text('開始提問')),
    ]),
    body('從養殖魚種出發'),
    LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final fish in fishSpecies)
            SizedBox(
              width: (constraints.maxWidth - 20) / 3,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xdde8f5fe),
                ),
                onPressed: () => onAsk('', fish),
                child: Column(
                  children: [
                    artwork('aquaculture_fish_favicon_v1'),
                    Text(fish),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
    panel([
      body('常見問題 · 畫面示例'),
      for (final q in sampleQuestions)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: artwork('watercolor_chat', 34),
          title: Text(q.$1),
          subtitle: Text(q.$3),
          onTap: () => onAsk(q.$1, q.$2),
        ),
    ]),
  ]);
}

class AskScreen extends StatefulWidget {
  const AskScreen({
    super.key,
    required this.store,
    this.question = '',
    this.species = '全部魚種',
  });
  final AppStore store;
  final String question, species;
  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  late final TextEditingController controller = TextEditingController(
    text: widget.question,
  );
  late String fish = widget.species;
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => pageContent([
    heading('今天想問什麼？'),
    body('補充魚種與觀察情況，讓問題更完整。'),
    DropdownButtonFormField<String>(
      initialValue: fish,
      decoration: const InputDecoration(labelText: '養殖魚種'),
      items: [
        for (final f in ['全部魚種', ...fishSpecies])
          DropdownMenuItem(value: f, child: Text(f)),
      ],
      onChanged: (value) => setState(() => fish = value!),
    ),
    TextField(
      controller: controller,
      minLines: 4,
      maxLines: 7,
      maxLength: 2000,
      decoration: const InputDecoration(
        labelText: '你的問題',
        hintText: '例如：虱目魚遇到寒流，應先確認哪些資料？',
      ),
    ),
    if (error != null)
      Text(error!, style: const TextStyle(color: Color(0xff943e36))),
    FilledButton(
      onPressed: () {
        try {
          final id = widget.store.submit(controller.text, fish);
          setState(() => error = null);
          openPage(context, AnswerScreen(store: widget.store, id: id));
        } on StateError catch (e) {
          setState(() => error = e.message.toString());
        }
      },
      child: const Text('送出問題'),
    ),
    body('目前不會呼叫正式模型。測試情境可在「我的」切換。'),
  ]);
}

class AnswerScreen extends StatelessWidget {
  const AnswerScreen({super.key, required this.store, required this.id});
  final AppStore store;
  final String id;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final job = store.findJob(id);
      if (job == null) {
        return DetailPage(
          title: '回答詳情',
          child: pageContent([body('找不到這筆示範紀錄。')]),
        );
      }
      final answer = job.answer;
      return DetailPage(
        title: '回答詳情',
        child: pageContent([
          body('${job.species} · M2 · 示範資料'),
          heading(job.question),
          if (job.status == JobStatus.running)
            panel([
              const Center(child: CircularProgressIndicator()),
              body('正在模擬處理。可以離開畫面，稍後從問答紀錄查看。'),
            ]),
          if (job.status == JobStatus.failed)
            panel([body(job.error ?? '問答未完成。')]),
          if (answer != null) ...[
            body(answerLabel(answer.status)),
            panel([body(answer.text)]),
            for (final missing in answer.missing) body('尚需補充：$missing'),
            if (answer.sources.isNotEmpty) ...[
              OutlinedButton(
                onPressed: () =>
                    openPage(context, SourceScreen(sources: answer.sources)),
                child: const Text('查看引用來源（示範）'),
              ),
              FilledButton(
                onPressed: () {
                  store.save(job);
                  openPage(context, NoteScreen(store: store, id: id));
                },
                child: Text(store.findSaved(id) == null ? '收藏這則回答' : '查看個人筆記'),
              ),
            ] else
              body('本次沒有可顯示的引用來源。'),
            OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已完成回報操作示範，未傳送資料。'))),
              child: const Text('模擬回報回答有疑問'),
            ),
          ],
          OutlinedButton(
            onPressed: () => openPage(
              context,
              DetailPage(
                title: '重新提問',
                child: AskScreen(
                  store: store,
                  question: job.question,
                  species: job.species,
                ),
              ),
            ),
            child: const Text('補充條件，重新提問'),
          ),
        ]),
      );
    },
  );
}

class SourceScreen extends StatelessWidget {
  const SourceScreen({super.key, required this.sources});
  final List<SourceEvidence> sources;
  @override
  Widget build(BuildContext context) => DetailPage(
    title: '引用來源',
    child: pageContent([
      heading('每個重點，都能追溯。'),
      body('以下為來源畫面占位，非真實文件或養殖依據。'),
      for (final source in sources)
        panel([
          heading(source.title),
          body(source.locator),
          body(source.quote),
        ]),
    ]),
  );
}

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String query = '', fish = '全部魚種';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final filtered = widget.store.saved.where(
        (s) =>
            (fish == '全部魚種' || s.job.species == fish) &&
            '${s.job.question} ${s.note}'.contains(query.trim()),
      );
      return pageContent([
        heading('留下有用的知識'),
        body('原回答與個人筆記分開保存。'),
        TextField(
          decoration: const InputDecoration(labelText: '搜尋收藏'),
          onChanged: (value) => setState(() => query = value),
        ),
        DropdownButtonFormField<String>(
          initialValue: fish,
          decoration: const InputDecoration(labelText: '依魚種篩選'),
          items: [
            for (final f in ['全部魚種', ...fishSpecies])
              DropdownMenuItem(value: f, child: Text(f)),
          ],
          onChanged: (value) => setState(() => fish = value!),
        ),
        if (filtered.isEmpty)
          panel([
            body(
              widget.store.saved.isEmpty
                  ? '還沒有收藏。先完成一次問答，再收藏有來源的回答。'
                  : '沒有符合條件的收藏。',
            ),
          ]),
        for (final item in filtered)
          panel([
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.job.question),
              subtitle: Text(item.note.isEmpty ? '點選後新增個人筆記' : item.note),
              leading: artwork('watercolor_knowledge'),
              onTap: () => openPage(
                context,
                NoteScreen(store: widget.store, id: item.job.id),
              ),
            ),
          ]),
      ]);
    },
  );
}

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key, required this.store, required this.id});
  final AppStore store;
  final String id;
  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  late final TextEditingController controller = TextEditingController(
    text: widget.store.findSaved(widget.id)?.note ?? '',
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.store.findSaved(widget.id);
    if (item == null) {
      return DetailPage(title: '收藏與筆記', child: pageContent([body('這則收藏已移除。')]));
    }
    return DetailPage(
      title: '收藏與個人筆記',
      child: pageContent([
        heading(item.job.question),
        panel([
          body('原回答快照 · 示範'),
          body(item.job.answer!.text),
          OutlinedButton(
            onPressed: () => openPage(
              context,
              SourceScreen(sources: item.job.answer!.sources),
            ),
            child: const Text('查看引用來源（示範）'),
          ),
        ]),
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          maxLength: 8000,
          decoration: const InputDecoration(labelText: '我的筆記'),
        ),
        body('個人筆記不會改寫原回答，也不會成為知識庫證據。'),
        FilledButton(
          onPressed: () {
            widget.store.updateNote(widget.id, controller.text);
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('已儲存到本次使用期間。')));
          },
          child: const Text('儲存示範筆記'),
        ),
        OutlinedButton(
          onPressed: () async {
            final remove = await confirm(
              context,
              '取消這則收藏？',
              '示範收藏與筆記會移除，問答紀錄仍會保留。',
            );
            if (!remove || !context.mounted) return;
            widget.store.removeSaved(widget.id);
            Navigator.pop(context);
          },
          child: const Text('取消收藏'),
        ),
      ]),
    );
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('確認'),
          ),
        ],
      ),
    ) ??
    false;

class MeScreen extends StatelessWidget {
  const MeScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => pageContent([
      heading('示範養殖夥伴'),
      panel([
        body('正式帳號與雲端保存尚未接入。'),
        OutlinedButton(
          onPressed: () => openPage(context, HistoryScreen(store: store)),
          child: Text('問答紀錄 · ${store.jobs.length} 筆'),
        ),
        body('服務狀態：示範模式，未連接正式服務。'),
      ]),
      body('開發用問答情境'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final scenario in DemoScenario.values)
            ChoiceChip(
              label: Text(scenarioLabel(scenario)),
              selected: store.scenario == scenario,
              onSelected: (_) => store.setScenario(scenario),
            ),
        ],
      ),
      OutlinedButton(
        onPressed: () async {
          if (await confirm(context, '清除示範資料？', '只會移除本次使用期間的問答、收藏與筆記。')) {
            store.clear();
          }
        },
        child: const Text('清除示範資料'),
      ),
      OutlinedButton(onPressed: store.logout, child: const Text('登出示範帳號')),
    ]),
  );
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => DetailPage(
      title: '問答紀錄',
      child: pageContent([
        heading('回顧每一次提問'),
        if (store.jobs.isEmpty) body('從你的第一個問題開始。'),
        for (final job in store.jobs)
          panel([
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(job.question),
              subtitle: Text(
                '${job.at.toLocal().toString().substring(0, 16)} · ${job.status == JobStatus.running
                    ? '處理中'
                    : job.status == JobStatus.done
                    ? '已完成'
                    : '未完成'}',
              ),
              leading: artwork('watercolor_history'),
              onTap: () =>
                  openPage(context, AnswerScreen(store: store, id: job.id)),
            ),
          ]),
      ]),
    ),
  );
}
