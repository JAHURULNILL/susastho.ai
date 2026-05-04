const FOOD_REFERENCE = [
  {
    name: 'পান্তা ভাত',
    aliases: ['পান্তা', 'fermented rice', 'panta bhat'],
    notes: [
      'এটি সাধারণ সাদা ভাতের মতো না; ভিজিয়ে ও হালকা ferment হওয়ায় digestibility আলাদা হতে পারে',
      'প্রোবায়োটিক উপকারিতা ও hydration angle consider করবে',
      'লবণ, ভর্তা, ভাজি বা কাঁচা মরিচের সঙ্গে খেলে sodium impactও ধরবে',
    ],
  },
  {
    name: 'হাঁসের ডিম',
    aliases: ['duck egg', 'হাঁসের ডিম'],
    notes: [
      'মুরগির ডিমের তুলনায় ক্যালরি, ফ্যাট ও cholesterol একটু বেশি ধরবে',
      'প্রোটিন ঘন, কিন্তু heart রোগ বা high cholesterol context-এ সতর্কতা দেবে',
    ],
  },
  {
    name: 'খাঁটি ঘি',
    aliases: ['ghee', 'ঘি'],
    notes: [
      'ছোট portion-এই high fat ও high calorie',
      'flavor benefit থাকলেও obesity, belly fat, fatty liver context-এ portion-specific warning দেবে',
    ],
  },
  {
    name: 'কালোজিরা',
    aliases: ['nigella', 'কালোজিরা'],
    notes: [
      'এটি high-calorie main item না; garnish বা medicinal tiny-portion context বুঝবে',
      'anti-inflammatory বা digestive angle থাকলে concise note দেবে',
    ],
  },
  {
    name: 'মসুর ডাল',
    aliases: ['lentil', 'মসুর ডাল', 'ডাল'],
    notes: [
      'protein + fiber source হিসেবে ধরবে',
      'ভাজা পেঁয়াজ, তেল, ঘনত্ব অনুযায়ী calorie variance explain করবে',
    ],
  },
  {
    name: 'রুই মাছ',
    aliases: ['rohu', 'rui mach', 'রুই'],
    notes: [
      'lean-to-moderate protein মাছ হিসেবে ধরবে',
      'ভুনা/ঝোল/ভাজি cooking method অনুযায়ী তেল impact adjust করবে',
    ],
  },
  {
    name: 'শাক',
    aliases: ['leafy greens', 'শাক'],
    notes: [
      'low calorie, fiber ও micronutrient positive signal',
      'অতিরিক্ত তেল বা ভাজি হলে সেই effect আলাদা ধরবে',
    ],
  },
  {
    name: 'ভর্তা',
    aliases: ['bhorta', 'ভর্তা'],
    notes: [
      'ingredient-dependent; আলু ভর্তা, বেগুন ভর্তা, টমেটো ভর্তা আলাদা reasoning',
      'সরিষার তেল ও লবণ quantity context ধরবে',
    ],
  },
  {
    name: 'চিড়া',
    aliases: ['flattened rice', 'চিড়া'],
    notes: [
      'breakfast/light carb হিসেবে ধরবে',
      'দুধ, কলা, চিনি, দই থাকলে glycemic impact adjust করবে',
    ],
  },
  {
    name: 'ইলিশ',
    aliases: ['hilsa', 'ইলিশ'],
    notes: [
      'fatty fish হিসেবে omega-rich angle ধরবে',
      'তেলে ভাজা হলে calorie load ও digestion impact আলাদা করবে',
    ],
  },
];

function buildLocalFoodKnowledge(description = '') {
  const text = String(description || '').toLowerCase();
  const matched = FOOD_REFERENCE.filter((item) =>
    item.aliases.some((alias) => text.includes(alias.toLowerCase())),
  );
  const selected = matched.length > 0 ? matched : FOOD_REFERENCE.slice(0, 6);
  return selected
    .map(
      (item) =>
        `- ${item.name}: ${item.notes.join(' | ')}`,
    )
    .join('\n');
}

module.exports = {
  buildLocalFoodKnowledge,
};
