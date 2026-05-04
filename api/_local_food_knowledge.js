function item(name, aliases = [], tags = []) {
  return { name, aliases, tags };
}

function group(category, defaultTags, entries) {
  return entries.map((entry) => {
    if (typeof entry === 'string') {
      return { category, name: entry, aliases: [], tags: [...defaultTags] };
    }

    return {
      category,
      name: entry.name,
      aliases: entry.aliases || [],
      tags: [...defaultTags, ...(entry.tags || [])],
    };
  });
}

const FOOD_REFERENCE = [
  ...group('ভাত ও চালের খাবার', ['high_carb', 'grain'], [
    item('সাদা ভাত', ['ভাত', 'plain rice']),
    item('লাল চালের ভাত', ['brown rice bangla', 'red rice']),
    item('আতপ চালের ভাত', ['আতপ ভাত']),
    item('সিদ্ধ চালের ভাত', ['সিদ্ধ ভাত', 'boiled rice']),
    item('পান্তা ভাত', ['panta bhat', 'fermented rice'], ['fermented', 'probiotic', 'iron_support']),
    item('মুগ ডালের খিচুড়ি', ['মুগ খিচুড়ি'], ['balanced', 'protein_support']),
    item('সবজি খিচুড়ি', ['vegetable khichuri'], ['fiber_support']),
    item('ভুনা খিচুড়ি', ['bhuna khichuri'], ['oily']),
    item('নরম খিচুড়ি', ['soft khichuri'], ['gentle_digestion']),
    item('ইলিশ খিচুড়ি', ['ilish khichuri'], ['omega3']),
    item('ছোলার পোলাও', ['cholar polao'], ['protein_support']),
    item('মোরগ পোলাও', ['morog polao'], ['oily', 'protein_support']),
    item('পোলাও', ['polao', 'pilaf']),
    item('বাসমতি পোলাও', ['basmati polao']),
    item('তেহারি', ['tehari'], ['oily']),
    item('কাচ্চি বিরিয়ানি', ['kacchi biryani'], ['oily', 'red_meat']),
    item('গরুর বিরিয়ানি', ['beef biryani'], ['oily', 'red_meat']),
    item('মুরগির বিরিয়ানি', ['chicken biryani'], ['oily', 'protein_support']),
    item('জর্দা ভাত', ['jorda rice'], ['sweet']),
    item('চালের পায়েস', ['rice pudding', 'payesh'], ['sweet', 'calcium_support']),
    item('ফিরনি', ['firni'], ['sweet', 'calcium_support']),
    item('সেমাই', ['shemai', 'semai'], ['sweet']),
    item('চিড়ার পোলাও', ['chira polao'], ['light_meal']),
    item('চাল ভাজা', ['fried rice bangla'], ['oily']),
    item('দুধভাত', ['milk rice'], ['calcium_support']),
    item('মুড়ি ভাত', ['muri bhat'], ['light_meal']),
    item('খুদের ভাত', ['broken rice meal']),
  ]),
  ...group('ডাল ও ডালজাতীয়', ['plant_protein', 'fiber_support'], [
    item('মসুর ডাল', ['lentil soup', 'musur dal'], ['iron_support']),
    item('মুগ ডাল', ['moog dal', 'mung dal'], ['gentle_digestion']),
    item('বুটের ডাল', ['booter dal', 'chana dal']),
    item('ছোলার ডাল', ['cholar dal']),
    item('অড়হর ডাল', ['arhar dal', 'toor dal']),
    item('কলাই ডাল', ['kolai dal']),
    item('মাষকলাই ডাল', ['mashkalai dal']),
    item('মটর ডাল', ['motor dal']),
    item('ডাল ভুনা', ['bhuna dal'], ['oily']),
    item('ডালনা ডাল', ['thick dal']),
    item('শুঁটকি ডাল', ['shutki dal'], ['salty']),
    item('মিশ্র ডাল', ['mixed dal']),
    item('সবজি ডাল', ['vegetable dal']),
    item('ডাবলি ডাল', ['double dal']),
  ]),
  ...group('মাছ ও সামুদ্রিক খাবার', ['protein_support'], [
    item('ইলিশ মাছ', ['hilsa', 'ilish'], ['omega3']),
    item('সরষে ইলিশ', ['sorshe ilish'], ['omega3', 'oily']),
    item('ইলিশ ভাজা', ['fried hilsa'], ['omega3', 'fried']),
    item('রুই মাছ', ['rui mach', 'rohu fish']),
    item('রুই মাছের ঝোল', ['rui jhol']),
    item('কাতলা মাছ', ['katla fish']),
    item('মৃগেল মাছ', ['mrigel fish']),
    item('পাঙ্গাশ মাছ', ['pangash fish'], ['fatty']),
    item('বোয়াল মাছ', ['boal fish']),
    item('শিং মাছ', ['shing fish']),
    item('শিং মাছের ঝোল', ['shing jhol'], ['gentle_digestion']),
    item('মাগুর মাছ', ['magur fish'], ['gentle_digestion']),
    item('কৈ মাছ', ['koi fish']),
    item('কৈ মাছের দোপেঁয়াজা', ['koi dopeyaza'], ['oily']),
    item('টেংরা মাছ', ['tengra fish']),
    item('টেংরা মাছের ঝোল', ['tengra jhol']),
    item('পাবদা মাছ', ['pabda fish']),
    item('পুঁটি মাছ', ['puti fish']),
    item('কাঁচকি মাছ', ['kachki fish']),
    item('বাটা মাছ', ['bata fish']),
    item('চিংড়ি মাছ', ['chingri', 'shrimp'], ['mineral_support']),
    item('গলদা চিংড়ি', ['golda chingri'], ['mineral_support']),
    item('চিংড়ি মালাইকারি', ['chingri malaikari'], ['oily']),
    item('শুঁটকি মাছ', ['shutki fish'], ['salty']),
    item('লইট্টা শুঁটকি', ['loitta shutki'], ['salty']),
    item('রূপচাঁদা মাছ', ['rupchanda fish']),
    item('কোরাল মাছ', ['koral fish']),
    item('ফলুই মাছ', ['folui fish']),
    item('চাপিলা মাছ', ['chapila fish']),
    item('তেলাপিয়া মাছ', ['tilapia fish']),
    item('ফেসা মাছ', ['fesha fish']),
    item('বেলে মাছ', ['bele fish']),
    item('মাছের ঝোল', ['fish curry']),
    item('মাছ ভুনা', ['fish bhuna'], ['oily']),
  ]),
  ...group('মাংস, ডিম ও প্রোটিন', ['protein_support'], [
    item('গরুর মাংস', ['beef curry'], ['red_meat']),
    item('গরুর ভুনা', ['beef bhuna'], ['red_meat', 'oily']),
    item('গরুর কিমা', ['beef mince'], ['red_meat']),
    item('গরুর কলিজা', ['beef liver'], ['iron_support']),
    item('খাসির মাংস', ['mutton curry'], ['red_meat', 'oily']),
    item('হাঁসের মাংস', ['duck curry'], ['fatty']),
    item('মুরগির ঝোল', ['chicken curry']),
    item('দেশি মুরগির ঝোল', ['deshi chicken curry']),
    item('মুরগির রোস্ট', ['chicken roast'], ['oily']),
    item('মুরগির রেজালা', ['chicken rezala'], ['oily']),
    item('মুরগির কলিজা', ['chicken liver'], ['iron_support']),
    item('কলিজা ভুনা', ['liver bhuna'], ['iron_support', 'oily']),
    item('নেহারি', ['nehari'], ['oily']),
    item('হালিম', ['haleem'], ['balanced', 'fiber_support']),
    item('কাবাব', ['kebab'], ['oily']),
    item('শিক কাবাব', ['seekh kebab'], ['oily']),
    item('ডিম ভাজি', ['egg fry']),
    item('ডিমের ঝোল', ['egg curry']),
    item('ডিম ভুনা', ['egg bhuna'], ['oily']),
    item('মুরগির ডিম', ['hen egg'], ['protein_support']),
    item('হাঁসের ডিম', ['duck egg'], ['protein_support', 'fatty', 'iron_support']),
    item('ডিম খিচুড়ি', ['egg khichuri'], ['balanced']),
  ]),
  ...group('শাক ও সবজি', ['fiber_support', 'micronutrient'], [
    item('লাল শাক', ['lal shak'], ['iron_support']),
    item('পুঁই শাক', ['pui shak']),
    item('ডাটা শাক', ['data shak']),
    item('কলমি শাক', ['kolmi shak']),
    item('পাট শাক', ['pat shak']),
    item('কচু শাক', ['kochu shak']),
    item('কচুর লতি', ['kochu loti']),
    item('মুলা শাক', ['mula shak']),
    item('সজনে পাতা', ['sojne pata'], ['iron_support']),
    item('লাউ শাক', ['lau shak']),
    item('মিষ্টি কুমড়া', ['pumpkin'], ['vitamin_a']),
    item('চাল কুমড়া', ['chalkumra']),
    item('লাউ', ['bottle gourd'], ['hydrating']),
    item('ঝিঙা', ['jhinga']),
    item('চিচিঙ্গা', ['snake gourd']),
    item('করলা', ['bitter gourd'], ['blood_sugar_support']),
    item('উচ্ছে', ['uchche'], ['blood_sugar_support']),
    item('পটল', ['pointed gourd']),
    item('ঢেঁড়স', ['okra'], ['gentle_digestion']),
    item('বাঁধাকপি', ['cabbage']),
    item('ফুলকপি', ['cauliflower']),
    item('শিম', ['shim']),
    item('বরবটি', ['barboti']),
    item('মটরশুঁটি', ['green peas']),
    item('কাঁচা কলা', ['green banana']),
    item('কাঁচা পেঁপে', ['green papaya'], ['gentle_digestion']),
    item('পেঁপে ভাজি', ['papaya fry']),
    item('বেগুন তরকারি', ['eggplant curry']),
    item('বেগুন ভাজি', ['begun bhaji'], ['fried']),
    item('মিষ্টি আলু', ['sweet potato']),
    item('ওল', ['yam']),
    item('কচু', ['taro']),
    item('শজনে ডাঁটা', ['drumstick vegetable']),
    item('আলু ফুলকপি', ['alu fulkopi']),
    item('মিশ্র সবজি', ['mixed vegetables']),
    item('লাবড়া', ['labra']),
    item('চচ্চড়ি', ['chocchori']),
    item('শুক্তো', ['shukto'], ['gentle_digestion']),
    item('কপি ভাজি', ['cabbage fry']),
    item('মুলা ভাজি', ['radish fry']),
    item('সবজি ভুনা', ['vegetable bhuna'], ['oily']),
    item('সবজি স্টু', ['vegetable stew'], ['gentle_digestion']),
  ]),
  ...group('ভর্তা, ভাজা ও সাইড', ['side_dish'], [
    item('আলু ভর্তা', ['aloo bhorta']),
    item('বেগুন ভর্তা', ['begun bhorta']),
    item('টমেটো ভর্তা', ['tomato bhorta']),
    item('ধনেপাতা ভর্তা', ['dhonepata bhorta']),
    item('শুঁটকি ভর্তা', ['shutki bhorta'], ['salty']),
    item('চিংড়ি ভর্তা', ['chingri bhorta']),
    item('কাঁচকলা ভর্তা', ['green banana bhorta']),
    item('ডাল ভর্তা', ['dal bhorta']),
    item('ডিম ভর্তা', ['egg bhorta']),
    item('কলিজা ভর্তা', ['kolija bhorta'], ['iron_support']),
    item('কাঁঠালের বিচি ভর্তা', ['jackfruit seed bhorta']),
    item('রসুন ভর্তা', ['garlic bhorta']),
    item('কাঁচামরিচ ভর্তা', ['green chili bhorta']),
    item('শুকনা মরিচ ভর্তা', ['dry chili bhorta']),
    item('সরিষা বাটা', ['mustard paste']),
    item('নারকেল চাটনি', ['coconut chutney']),
    item('কাঁচা আম ভর্তা', ['raw mango bhorta']),
    item('চিংড়ি ভাজা', ['fried shrimp'], ['fried']),
    item('মাছ ভাজা', ['fried fish'], ['fried']),
    item('বেগুনি', ['eggplant fritter'], ['fried']),
    item('পেঁয়াজু', ['piyaju'], ['fried']),
    item('আলুর চপ', ['alur chop'], ['fried']),
    item('পাকোড়া', ['pakora'], ['fried']),
    item('পরোটা ভাজি', ['fried flatbread'], ['fried']),
  ]),
  ...group('নাস্তা, রুটি ও স্ট্রিট ফুড', ['quick_meal'], [
    item('চিড়া', ['chira', 'flattened rice'], ['light_meal']),
    item('দুধ চিড়া', ['milk chira'], ['calcium_support']),
    item('দই চিড়া', ['doi chira'], ['probiotic']),
    item('মুড়ি', ['muri', 'puffed rice'], ['light_meal']),
    item('মুড়ি মাখা', ['muri makha']),
    item('ঝালমুড়ি', ['jhalmuri']),
    item('চানাচুর', ['chanachur'], ['salty']),
    item('ঘুগনি', ['ghugni'], ['plant_protein']),
    item('মুড়ি-ঘুগনি', ['muri ghugni'], ['balanced']),
    item('ছোলা ভুনা', ['chola bhuna'], ['plant_protein']),
    item('রুটি', ['atta roti']),
    item('তন্দুরি রুটি', ['tandoori roti']),
    item('নান রুটি', ['naan'], ['refined_flour']),
    item('পরোটা', ['paratha'], ['oily']),
    item('লুচি', ['luchi'], ['fried']),
    item('পুরি', ['puri'], ['fried']),
    item('ডালপুরি', ['dal puri'], ['fried']),
    item('সবজি পরোটা', ['vegetable paratha'], ['oily']),
    item('বাখরখানি', ['bakarkhani'], ['refined_flour']),
    item('সিংগারা', ['singara'], ['fried']),
    item('সমুচা', ['samosa'], ['fried']),
    item('ফুচকা', ['fuchka', 'phuchka'], ['street_food']),
    item('চটপটি', ['chotpoti'], ['street_food', 'plant_protein']),
    item('হালিম-পরোটা', ['haleem paratha'], ['oily']),
    item('ডিম টোস্ট', ['egg toast']),
    item('সবজি রোল', ['vegetable roll'], ['street_food']),
    item('ডিম রোল', ['egg roll'], ['street_food']),
  ]),
  ...group('পিঠা, মিষ্টি ও ডেজার্ট', ['sweet'], [
    item('ভাপা পিঠা', ['bhapa pitha']),
    item('চিতই পিঠা', ['chitoi pitha']),
    item('পাটিসাপটা', ['patishapta']),
    item('দুধ পুলি', ['dudh puli']),
    item('পুলি পিঠা', ['puli pitha']),
    item('তেলের পিঠা', ['teler pitha'], ['fried']),
    item('পাকান পিঠা', ['pakan pitha'], ['fried']),
    item('নকশি পিঠা', ['nakshi pitha']),
    item('চিতই-ভর্তা', ['chitoi with bhorta']),
    item('পায়েস', ['payesh']),
    item('মিষ্টি দই', ['mishti doi'], ['probiotic', 'calcium_support']),
    item('টক দই', ['tok doi'], ['probiotic', 'calcium_support']),
    item('রসগোল্লা', ['rasgolla']),
    item('সন্দেশ', ['sandesh']),
    item('চমচম', ['chomchom']),
    item('কালোজাম মিষ্টি', ['kalojam sweet']),
    item('লাড্ডু', ['laddu']),
    item('মাওয়া', ['mawa sweet']),
    item('জিলাপি', ['jilapi'], ['fried']),
    item('জিলাপি-পুরি', ['jilapi puri'], ['fried']),
    item('শাহী টুকরা', ['shahi tukra']),
    item('দুধ সেমাই', ['milk semai']),
    item('ছানার মিষ্টি', ['chhana sweet']),
  ]),
  ...group('ফল, পানীয় ও আচার', ['micronutrient'], [
    item('আম', ['mango']),
    item('কাঁচা আম', ['raw mango']),
    item('কাঁঠাল', ['jackfruit']),
    item('কলা', ['banana']),
    item('পেয়ারা', ['guava'], ['vitamin_c']),
    item('পেঁপে', ['papaya'], ['gentle_digestion']),
    item('জাম', ['black plum']),
    item('লিচু', ['lychee']),
    item('তরমুজ', ['watermelon'], ['hydrating']),
    item('বাঙ্গি', ['melon'], ['hydrating']),
    item('ডাবের পানি', ['coconut water'], ['hydrating']),
    item('লেবুর শরবত', ['lemon sharbat'], ['hydrating', 'vitamin_c']),
    item('বেল শরবত', ['bel sharbat'], ['gentle_digestion']),
    item('আখের রস', ['sugarcane juice'], ['sweet']),
    item('ঘোল', ['ghol'], ['probiotic']),
    item('লাচ্ছি', ['lassi'], ['probiotic', 'calcium_support']),
    item('বোরহানি', ['borhani'], ['probiotic', 'digestion_support']),
    item('কাঁচা আমের আচার', ['raw mango achar'], ['salty']),
    item('জলপাই আচার', ['olive achar'], ['salty']),
    item('বরই আচার', ['boroi achar'], ['salty']),
    item('কুলের আচার', ['kul achar'], ['salty']),
    item('তেঁতুলের আচার', ['tetul achar'], ['salty']),
  ]),
];

const FOOD_COUNT = FOOD_REFERENCE.length;

const CATEGORY_SUMMARY = FOOD_REFERENCE.reduce((acc, food) => {
  acc[food.category] = (acc[food.category] || 0) + 1;
  return acc;
}, {});

const NOTE_BY_TAG = {
  fermented: 'ফারমেন্টেড হওয়ায় প্রোবায়োটিক ও হজম-সহায়ক বৈশিষ্ট্য থাকতে পারে',
  probiotic: 'হজম ও অন্ত্রের জন্য সহায়ক হতে পারে',
  iron_support: 'আয়রন বা রক্তস্বাস্থ্যের সহায়ক দিক থাকতে পারে',
  omega3: 'ওমেগা-৩ সমর্থন দিতে পারে',
  high_carb: 'কার্বোহাইড্রেট বেশি, তাই portion control গুরুত্বপূর্ণ',
  grain: 'শক্তির বড় উৎস, তবে পরিমাণ বুঝে খাওয়া ভালো',
  protein_support: 'প্রোটিনের ভালো উৎস হতে পারে',
  plant_protein: 'উদ্ভিজ্জ প্রোটিন ও আঁশের উৎস',
  fiber_support: 'আঁশ বেশি থাকায় তৃপ্তি ও হজমে সহায়ক হতে পারে',
  micronutrient: 'মাইক্রোনিউট্রিয়েন্ট সমৃদ্ধ হতে পারে',
  vitamin_a: 'ভিটামিন A সমর্থন দিতে পারে',
  vitamin_c: 'ভিটামিন C সমর্থন দিতে পারে',
  blood_sugar_support: 'গ্লাইসেমিক নিয়ন্ত্রণে তুলনামূলক সহায়ক হতে পারে',
  gentle_digestion: 'পেটে তুলনামূলক হালকা হতে পারে',
  hydration: 'পানিশূন্যতা কমাতে সহায়ক হতে পারে',
  hydrating: 'শরীর হাইড্রেট রাখতে সহায়ক হতে পারে',
  balanced: 'কার্ব, প্রোটিন ও তৃপ্তির মাঝামাঝি ভারসাম্য দিতে পারে',
  fatty: 'চর্বি তুলনামূলক বেশি, তাই পরিমাণ নিয়ন্ত্রণ দরকার',
  fried: 'ভাজা হওয়ায় তেল ও ক্যালরি বাড়তে পারে',
  oily: 'তেল/ঘি বেশি হওয়ার ঝুঁকি থাকে',
  red_meat: 'রেড মিট হওয়ায় portion ও frequency গুরুত্বপূর্ণ',
  sweet: 'চিনি বেশি, তাই ডায়াবেটিস বা ওজন নিয়ন্ত্রণে সতর্কতা দরকার',
  salty: 'লবণ বা সংরক্ষণজনিত sodium বেশি হতে পারে',
  refined_flour: 'পরিশোধিত আটা/ময়দা থাকলে দ্রুত ক্যালরি যোগ হতে পারে',
  light_meal: 'হালকা নাস্তা হিসেবে ভালো মানাতে পারে',
  quick_meal: 'দ্রুত খাওয়ার অপশন, তবে balance দেখা দরকার',
  side_dish: 'সাইড আইটেম হিসেবে portion ছোট রাখাই ভালো',
  street_food: 'রাস্তার খাবার হলে hygiene ও portion দুটোই জরুরি',
  calcium_support: 'ক্যালসিয়াম সমর্থন দিতে পারে',
  digestion_support: 'হজমে স্বস্তি দিতে পারে',
};

function normalize(text = '') {
  return String(text)
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tokenize(text = '') {
  return normalize(text)
    .split(' ')
    .map((token) => token.trim())
    .filter((token) => token.length >= 2);
}

function notesFromTags(tags = []) {
  const notes = [];
  for (const tag of tags) {
    const note = NOTE_BY_TAG[tag];
    if (note && !notes.includes(note)) {
      notes.push(note);
    }
  }
  return notes.slice(0, 3);
}

function scoreFood(food, tokens, rawText) {
  const haystack = normalize([food.name, food.category, ...(food.aliases || [])].join(' '));
  let score = 0;

  for (const token of tokens) {
    if (haystack.includes(token)) {
      score += token.length > 4 ? 3 : 2;
    }
  }

  if (rawText && haystack.includes(rawText)) {
    score += 4;
  }

  return score;
}

function formatFood(food) {
  const notes = notesFromTags(food.tags);
  const noteText = notes.length > 0
    ? notes.join('; ')
    : 'দেশীয় রান্না, উপাদান ও portion দেখে বিচার করতে হবে';
  return `- ${food.name} (${food.category}) — ${noteText}`;
}

function formatCategorySummary() {
  return Object.entries(CATEGORY_SUMMARY)
    .map(([category, count]) => `- ${category}: ${count}টি`)
    .join('\n');
}

function representativeFoods() {
  const representatives = [
    'পান্তা ভাত',
    'মসুর ডাল',
    'রুই মাছ',
    'ইলিশ মাছ',
    'গরুর মাংস',
    'মুরগির ঝোল',
    'হাঁসের ডিম',
    'লাল শাক',
    'করলা',
    'আলু ভর্তা',
    'ফুচকা',
    'চটপটি',
    'পোলাও',
    'খিচুড়ি',
    'ভাপা পিঠা',
    'মিষ্টি দই',
    'ডাবের পানি',
    'বোরহানি',
  ];

  return representatives
    .map((name) => FOOD_REFERENCE.find((food) => food.name === name))
    .filter(Boolean)
    .map(formatFood)
    .join('\n');
}

function buildLocalFoodKnowledge(description = '') {
  const rawText = normalize(description);
  const tokens = tokenize(description);

  const matched = FOOD_REFERENCE
    .map((food) => ({ food, score: scoreFood(food, tokens, rawText) }))
    .filter((entry) => entry.score > 0)
    .sort((left, right) => right.score - left.score)
    .slice(0, 22)
    .map((entry) => entry.food);

  const header = `বাংলাদেশি স্থানীয় খাদ্য-জ্ঞানভান্ডার: মোট ${FOOD_COUNT}টি শুধু বাংলাদেশি খাবারের reference আছে। কোনো বিদেশি খাবার, western substitute বা non-Bangladeshi example ব্যবহার করবে না।`;
  const summary = `ক্যাটাগরি সারাংশ:\n${formatCategorySummary()}`;

  if (!description || matched.length === 0) {
    return `${header}

${summary}

ছবি বা টেক্সট থেকে exact match না পেলেও নিচের representative দেশীয় খাবারগুলো মাথায় রেখে reasoning করবে:
${representativeFoods()}`;
  }

  const matchedLines = matched.map(formatFood).join('\n');
  return `${header}

${summary}

ইনপুটের সাথে সবচেয়ে বেশি মিলে এমন দেশীয় খাবারগুলো:
${matchedLines}`;
}

module.exports = {
  FOOD_REFERENCE,
  FOOD_COUNT,
  buildLocalFoodKnowledge,
};
