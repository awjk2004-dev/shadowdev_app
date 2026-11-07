import 'package:flutter/material.dart';

import '../models/skill.dart';

/// أبعاد لوحة الرسم المنطقية لشجرة المهارات.
/// نستخدم `constrained: false` داخل InteractiveViewer حتى نرسم على مساحة
/// ثابتة ونترك التكبير/التصغير يتولى بقية العمل.
abstract final class SkillTreeLayout {
  static const double canvasWidth = 1400;
  static const double canvasHeight = 1800;

  /// قطر دائرة المهارة.
  static const double nodeDiameter = 72;

  /// عرض/ارتفاع صندوق العقدة (الدائرة + العنوان).
  static const double nodeBoxWidth = 150;
  static const double nodeBoxHeight = 132;

  static const double minScale = 0.4;
  static const double maxScale = 2.5;
  static const double initialScale = 0.75;
}

/// الشجرة الافتراضية.
///
/// لإضافة مهارات جديدة برمجياً استخدم `SkillTreeProvider.addSkill`.
const List<Skill> defaultSkillTree = <Skill>[
  Skill(
    id: 'discipline',
    title: 'الانضباط الأساسي',
    description:
        'أساس كل تقدم. الالتزام الصغير المتكرر يتغلب على الحماس المؤقت.',
    type: SkillType.passive,
    cost: 1,
    x: 700,
    y: 1560,
    icon: Icons.shield,
  ),
  Skill(
    id: 'focus',
    title: 'التركيز',
    description: 'زيادة القدرة على البقاء في المهمة الواحدة دون تشتت.',
    type: SkillType.passive,
    cost: 1,
    x: 300,
    y: 1260,
    prerequisites: ['discipline'],
    icon: Icons.center_focus_strong,
  ),
  Skill(
    id: 'awareness',
    title: 'الوعي',
    description: 'ملاحظة أنماطك اليومية ومعرفة ما يستهلك طاقتك.',
    type: SkillType.active,
    cost: 1,
    x: 700,
    y: 1260,
    prerequisites: ['discipline'],
    icon: Icons.visibility,
  ),
  Skill(
    id: 'endurance',
    title: 'التحمل',
    description: 'القدرة على الاستمرار عندما تخف الحماسة الأولى.',
    type: SkillType.passive,
    cost: 1,
    x: 1100,
    y: 1260,
    prerequisites: ['discipline'],
    icon: Icons.favorite,
  ),
  Skill(
    id: 'deep_work',
    title: 'العمل العميق',
    description: 'جلسات طويلة من التركيز بلا مقاطعات لبناء مخرجات حقيقية.',
    type: SkillType.passive,
    cost: 2,
    x: 220,
    y: 960,
    prerequisites: ['focus'],
    icon: Icons.psychology,
  ),
  Skill(
    id: 'mind_fortress',
    title: 'حصن العقل',
    description: 'مقاومة المشتتات والأفكار السلبية أثناء العمل.',
    type: SkillType.passive,
    cost: 2,
    x: 480,
    y: 960,
    prerequisites: ['focus'],
    icon: Icons.castle,
  ),
  Skill(
    id: 'balance',
    title: 'الاتزان',
    description: 'موازنة العمل والراحة والعلاقات دون انهيار أي جانب.',
    type: SkillType.passive,
    cost: 2,
    x: 700,
    y: 960,
    prerequisites: ['awareness'],
    icon: Icons.balance,
  ),
  Skill(
    id: 'void_step',
    title: 'خطوة الفراغ',
    description: 'التقدم السريع في المهام الصغيرة المتتالية دون توقف.',
    type: SkillType.active,
    cost: 2,
    x: 880,
    y: 960,
    prerequisites: ['endurance'],
    icon: Icons.air,
  ),
  Skill(
    id: 'agility',
    title: 'الرشاقة',
    description: 'التحرك بين المهام بذكاء والحفاظ على زخم الإنجاز.',
    type: SkillType.active,
    cost: 2,
    x: 1120,
    y: 960,
    prerequisites: ['endurance'],
    icon: Icons.bolt,
  ),
  Skill(
    id: 'iron_will',
    title: 'الإرادة الحديدية',
    description: 'تنفيذ ما قررته حتى عندما لا ترغب في ذلك.',
    type: SkillType.passive,
    cost: 3,
    x: 350,
    y: 660,
    prerequisites: ['mind_fortress'],
    icon: Icons.security,
  ),
  Skill(
    id: 'shadow_mind',
    title: 'عقل الظل',
    description: 'تحويل الضغط والتعب إلى تركيز بارد وحساب هادئ.',
    type: SkillType.passive,
    cost: 3,
    x: 560,
    y: 660,
    prerequisites: ['deep_work', 'mind_fortress'],
    icon: Icons.dark_mode,
  ),
  Skill(
    id: 'phantom',
    title: 'الظل الخفي',
    description: 'إنجاز العمل بهدوء بعيداً عن الضوضاء والمقاطعات.',
    type: SkillType.active,
    cost: 3,
    x: 880,
    y: 660,
    prerequisites: ['void_step'],
    icon: Icons.blur_on,
  ),
  Skill(
    id: 'battle_focus',
    title: 'تركيز القتال',
    description: 'دخول حالة انغماس كامل عند اقتراب الموعد النهائي.',
    type: SkillType.active,
    cost: 3,
    x: 1120,
    y: 660,
    prerequisites: ['void_step', 'agility'],
    icon: Icons.sports_martial_arts,
  ),
  Skill(
    id: 'shadow_master',
    title: 'سيد الظل',
    description: 'السيطرة على وقتك وطاقتك لتصبح أنت من يقود النظام.',
    type: SkillType.active,
    cost: 5,
    x: 700,
    y: 360,
    prerequisites: ['shadow_mind', 'phantom'],
    icon: Icons.auto_awesome,
  ),
  Skill(
    id: 'ascended',
    title: 'الارتقاء',
    description: 'قمة الشجرة: نظام حياة متكامل يعمل حتى في أصعب الأيام.',
    type: SkillType.passive,
    cost: 8,
    x: 700,
    y: 120,
    prerequisites: ['shadow_master', 'iron_will', 'battle_focus'],
    icon: Icons.workspace_premium,
  ),
];
