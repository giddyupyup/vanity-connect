const DIGIT_TO_LETTERS: Record<string, string[]> = {
  "2": ["A", "B", "C"],
  "3": ["D", "E", "F"],
  "4": ["G", "H", "I"],
  "5": ["J", "K", "L"],
  "6": ["M", "N", "O"],
  "7": ["P", "Q", "R", "S"],
  "8": ["T", "U", "V"],
  "9": ["W", "X", "Y", "Z"]
};

const LETTER_TO_DIGIT = Object.entries(DIGIT_TO_LETTERS).reduce<Record<string, string>>(
  (map, [digit, letters]) => {
    for (const letter of letters) {
      map[letter] = digit;
    }
    return map;
  },
  {}
);

const WORD_DICTIONARY = [
  "FLOWERS",
  "SUPPORT",
  "SERVICE",
  "ACCOUNT",
  "WELCOME",
  "CONTACT",
  "HOTLINE",
  "HELP",
  "CALL",
  "SALES",
  "ORDER",
  "HOME",
  "TEAM",
  "CARE",
  "CHAT",
  "FAST",
  "SAFE",
  "BEST",
  "STAR",
  "SHOP"
];

function digitsForWord(word: string): string {
  return word
    .toUpperCase()
    .split("")
    .map((char) => LETTER_TO_DIGIT[char] ?? "")
    .join("");
}

function fallbackLettersForDigit(digit: string): string {
  const letters = DIGIT_TO_LETTERS[digit];
  if (!letters) {
    return digit;
  }
  return letters[0];
}

export function normalizePhoneNumber(input: string): string {
  const digits = input.replace(/\D/g, "");

  if (digits.length === 11 && digits.startsWith("1")) {
    return digits.slice(1);
  }

  if (digits.length >= 10) {
    return digits.slice(-10);
  }

  return digits;
}

function formatUsNumber(tenDigits: string): string {
  const area = tenDigits.slice(0, 3);
  const local = tenDigits.slice(3);

  if (/[A-Z]/.test(local)) {
    return `+1-${area}-${local}`;
  }

  const exchange = local.slice(0, 3);
  const subscriber = local.slice(3);
  return `+1-${area}-${exchange}-${subscriber}`;
}

function scoreCandidate(local7: string): number {
  const lettersCount = local7.replace(/[^A-Z]/g, "").length;
  const longestLetterRun = Math.max(...(local7.match(/[A-Z]+/g) ?? [""]).map((v) => v.length));
  return lettersCount * 5 + longestLetterRun * 10;
}

export function generateVanityNumbers(phoneNumber: string, limit = 5): string[] {
  const normalized = normalizePhoneNumber(phoneNumber);
  if (normalized.length !== 10) {
    return [];
  }

  const local7 = normalized.slice(3);
  const candidates = new Set<string>();

  for (const word of WORD_DICTIONARY) {
    const wordDigits = digitsForWord(word);
    if (wordDigits.length > local7.length) {
      continue;
    }

    if (local7.endsWith(wordDigits)) {
      const prefixDigits = local7.slice(0, local7.length - wordDigits.length);
      candidates.add(prefixDigits + word);
    }
  }

  const fallbackWord = local7
    .split("")
    .map((digit) => fallbackLettersForDigit(digit))
    .join("");

  candidates.add(fallbackWord);
  candidates.add(local7.slice(0, 3) + fallbackWord.slice(3));
  candidates.add(fallbackWord.slice(0, 3) + local7.slice(3));

  return [...candidates]
    .sort((a, b) => scoreCandidate(b) - scoreCandidate(a))
    .slice(0, limit)
    .map((local) => formatUsNumber(normalized.slice(0, 3) + local));
}
