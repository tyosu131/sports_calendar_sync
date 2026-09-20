/** Presentation-only evidence from J1/J2/J3 repository data and review docs. */
const CLUBS: readonly { japanese: string; aliases: readonly string[] }[] = [
  { japanese: "鹿島アントラーズ", aliases: ["Kashima", "Kashima Antlers", "Antlers"] },
  { japanese: "水戸ホーリーホック", aliases: ["Mito Hollyhock"] },
  { japanese: "浦和レッズ", aliases: ["Urawa Reds"] },
  { japanese: "ジェフユナイテッド千葉", aliases: ["JEF United Chiba", "JEF Chiba"] },
  { japanese: "柏レイソル", aliases: ["Kashiwa Reysol"] },
  { japanese: "ＦＣ東京", aliases: ["FC Tokyo"] },
  { japanese: "東京ヴェルディ", aliases: ["Tokyo Verdy"] },
  { japanese: "ＦＣ町田ゼルビア", aliases: ["FC Machida Zelvia", "Machida Zelvia"] },
  { japanese: "川崎フロンターレ", aliases: ["Kawasaki Frontale"] },
  { japanese: "横浜Ｆ・マリノス", aliases: ["Yokohama F. Marinos", "F. Marinos"] },
  { japanese: "清水エスパルス", aliases: ["Shimizu S-Pulse"] },
  { japanese: "名古屋グランパス", aliases: ["Nagoya Grampus"] },
  { japanese: "京都サンガF.C.", aliases: ["Kyoto Sanga F.C.", "Kyoto Sanga"] },
  { japanese: "ガンバ大阪", aliases: ["Gamba Osaka"] },
  { japanese: "セレッソ大阪", aliases: ["Cerezo Osaka"] },
  { japanese: "ヴィッセル神戸", aliases: ["Vissel Kobe"] },
  { japanese: "ファジアーノ岡山", aliases: ["Fagiano Okayama"] },
  { japanese: "サンフレッチェ広島", aliases: ["Sanfrecce Hiroshima"] },
  { japanese: "アビスパ福岡", aliases: ["Avispa Fukuoka"] },
  { japanese: "Ｖ・ファーレン長崎", aliases: ["V-Varen Nagasaki", "V. Varen Nagasaki"] },
  { japanese: "ベガルタ仙台", aliases: ["Vegalta Sendai"] },
  { japanese: "湘南ベルマーレ", aliases: ["Shonan Bellmare"] },
  { japanese: "ブラウブリッツ秋田", aliases: ["Blaublitz Akita"] },
  { japanese: "横浜ＦＣ", aliases: ["Yokohama FC"] },
  { japanese: "モンテディオ山形", aliases: ["Montedio Yamagata"] },
  { japanese: "栃木シティ", aliases: ["Tochigi City"] },
  { japanese: "栃木ＳＣ", aliases: ["Tochigi SC"] },
  { japanese: "ヴァンフォーレ甲府", aliases: ["Ventforet Kofu"] },
  { japanese: "藤枝ＭＹＦＣ", aliases: ["Fujieda MYFC"] },
  { japanese: "ジュビロ磐田", aliases: ["Jubilo Iwata"] },
  { japanese: "徳島ヴォルティス", aliases: ["Tokushima Vortis"] },
  { japanese: "アルビレックス新潟", aliases: ["Albirex Niigata"] },
  { japanese: "愛媛ＦＣ", aliases: ["Ehime FC"] },
  { japanese: "ザスパ群馬", aliases: ["Thespa Gunma", "Thespakusatsu Gunma"] },
  { japanese: "いわきＦＣ", aliases: ["Iwaki FC", "Iwaki"] },
  { japanese: "ＲＢ大宮アルディージャ", aliases: ["RB Omiya Ardija", "Omiya Ardija"] },
  { japanese: "北海道コンサドーレ札幌", aliases: ["Hokkaido Consadole Sapporo", "Consadole Sapporo"] },
  { japanese: "サガン鳥栖", aliases: ["Sagan Tosu"] },
  { japanese: "鹿児島ユナイテッドＦＣ", aliases: ["Kagoshima United"] },
  { japanese: "レノファ山口ＦＣ", aliases: ["Renofa Yamaguchi"] },
  { japanese: "ロアッソ熊本", aliases: ["Roasso Kumamoto"] },
  { japanese: "大分トリニータ", aliases: ["Oita Trinita"] },
  { japanese: "ヴァンラーレ八戸", aliases: ["Vanraure Hachinohe"] },
  { japanese: "ＦＣ岐阜", aliases: ["FC Gifu"] },
  { japanese: "松本山雅ＦＣ", aliases: ["Matsumoto Yamaga"] },
  { japanese: "福島ユナイテッドＦＣ", aliases: ["Fukushima United"] },
  { japanese: "カターレ富山", aliases: ["Kataller Toyama"] },
  { japanese: "高知ユナイテッドＳＣ", aliases: ["Kochi United"] },
  { japanese: "奈良クラブ", aliases: ["Nara Club"] },
  { japanese: "ＳＣ相模原", aliases: ["SC Sagamihara", "Sagamihara"] },
  { japanese: "ＡＣ長野パルセイロ", aliases: ["AC Nagano Parceiro", "Parceiro Nagano"] },
  { japanese: "ツエーゲン金沢", aliases: ["Zweigen Kanazawa", "Kanazawa"] },
  { japanese: "ＦＣ大阪", aliases: ["FC Osaka", "Osaka"] },
  { japanese: "ＦＣ今治", aliases: ["FC Imabari", "Imabari"] },
  { japanese: "カマタマーレ讃岐", aliases: ["Kamatamare Sanuki"] },
  { japanese: "テゲバジャーロ宮崎", aliases: ["Tegevajaro Miyazaki"] },
  { japanese: "ガイナーレ鳥取", aliases: ["Gainare Tottori"] },
  { japanese: "ギラヴァンツ北九州", aliases: ["Giravanz Kitakyushu", "Kitakyushu"] },
  { japanese: "ＦＣ琉球", aliases: ["FC Ryukyu", "Ryukyu"] },
  { japanese: "レイラック滋賀FC", aliases: ["Reilac Shiga FC", "Reilac Shiga", "Biwako Shiga"] },
];

export function normalizeClubDisplayKey(value: string): string {
  return value.normalize("NFKC").toLocaleLowerCase("en").replace(/[^a-z0-9]/g, "");
}

const JAPANESE_BY_NORMALIZED_ALIAS = new Map(CLUBS.flatMap((club) =>
  club.aliases.map((alias) => [normalizeClubDisplayKey(alias), club.japanese] as const)
));

export function japaneseClubDisplayName(value: string): string | undefined {
  return JAPANESE_BY_NORMALIZED_ALIAS.get(normalizeClubDisplayKey(value));
}
