// entry/src/main/ets/InputMethodExtensionAbility/model/TelexEngine.ets

export enum TelexActionKind {
  Insert = 0,
  Replace = 1,
  None = 2
}

export class TelexResult {
  kind: TelexActionKind = TelexActionKind.None;

  // Insert: ký tự vừa gõ (vd: "o")
  // Replace: full word mới (vd: "ô" hoặc "telex")
  text: string = '';

  // COMPAT: KeyboardController đang dùng newWord
  // Insert: full word sau khi insert (currentWord + keyChar)
  // Replace: full word mới
  newWord: string = '';
}

enum VowelGroup {
  A = 0,
  E = 1,
  I = 2,
  O = 3,
  U = 4,
  Y = 5,

  AA = 10, // â
  AW = 11, // ă
  EE = 12, // ê
  OO = 13, // ô
  OW = 14, // ơ
  UW = 15  // ư
}

class VowelInfo {
  base: string = '';
  group: VowelGroup = VowelGroup.A;
  tone: number = 0; // 0 none, 1..5
}

// ArkTS: tránh object-literal type {start,end}
class VowelSpan {
  start: number = 0;
  end: number = 0;
}

export class TelexEngine {
  modernOrthography: boolean = true;

  private compatFlag: boolean = false;

  // COMPAT CONSTRUCTOR: KeyboardController gọi new TelexEngine(true, false)
  constructor(modernOrthography: boolean = true, compatFlag: boolean = false) {
    this.modernOrthography = modernOrthography;
    this.compatFlag = compatFlag;
  }

  // COMPAT METHOD: KeyboardController gọi this.telex.apply(word, keyChar)
  apply(currentWord: string, keyChar: string): TelexResult {
    if (this.compatFlag) {
      // no-op: chỉ để tránh warning never read
    }
    return this.applyKey(currentWord, keyChar);
  }

  // ---------- Public API ----------
  applyKey(currentWord: string, keyChar: string): TelexResult {
    const out: TelexResult = new TelexResult();

    if (keyChar.length === 0) {
      out.kind = TelexActionKind.None;
      out.text = currentWord;
      out.newWord = currentWord;
      return out;
    }

    // Shape keys: a/e/o/w
    if (this.isShapeKey(keyChar)) {
      const next: string = this.applyShapeKey(currentWord, keyChar);
      if (next === currentWord) {
        out.kind = TelexActionKind.Insert;
        out.text = keyChar;
        out.newWord = currentWord + keyChar;
      } else {
        out.kind = TelexActionKind.Replace;
        out.text = next;
        out.newWord = next;
      }
      return out;
    }

    // Tone keys: s f r x j
    if (this.isToneKey(keyChar)) {
      const next: string = this.applyToneKey(currentWord, keyChar);
      if (next === currentWord) {
        out.kind = TelexActionKind.Insert;
        out.text = keyChar;
        out.newWord = currentWord + keyChar;
      } else {
        out.kind = TelexActionKind.Replace;
        out.text = next;
        out.newWord = next;
      }
      return out;
    }

    // Normal char
    out.kind = TelexActionKind.Insert;
    out.text = keyChar;
    out.newWord = currentWord + keyChar;
    return out;
  }

  // ---------- Key classification ----------
  private isToneKey(ch: string): boolean {
    const c: string = ch.toLowerCase();
    return c === 's' || c === 'f' || c === 'r' || c === 'x' || c === 'j';
  }

  private isShapeKey(ch: string): boolean {
    const c: string = ch.toLowerCase();
    return c === 'a' || c === 'e' || c === 'o' || c === 'w';
  }

  // ---------- Core vowel mapping ----------
  private toBaseLetter(ch: string): string {
    const info: VowelInfo | undefined = this.getVowelInfo(ch);
    if (!info) return ch.toLowerCase();
    return info.base;
  }

  // tone order: 1 sắc,2 huyền,3 hỏi,4 ngã,5 nặng
  private toneOfKey(k: string): number {
    const c: string = k.toLowerCase();
    if (c === 's') return 1;
    if (c === 'f') return 2;
    if (c === 'r') return 3;
    if (c === 'x') return 4;
    if (c === 'j') return 5;
    return 0;
  }

  private getVowelInfo(ch: string): VowelInfo | undefined {
    const c: string = ch;

    const make = (base: string, group: VowelGroup, tone: number): VowelInfo => {
      const v: VowelInfo = new VowelInfo();
      v.base = base;
      v.group = group;
      v.tone = tone;
      return v;
    };

    switch (c) {
      // a
      case 'a': return make('a', VowelGroup.A, 0);
      case 'á': return make('a', VowelGroup.A, 1);
      case 'à': return make('a', VowelGroup.A, 2);
      case 'ả': return make('a', VowelGroup.A, 3);
      case 'ã': return make('a', VowelGroup.A, 4);
      case 'ạ': return make('a', VowelGroup.A, 5);

      // ă
      case 'ă': return make('a', VowelGroup.AW, 0);
      case 'ắ': return make('a', VowelGroup.AW, 1);
      case 'ằ': return make('a', VowelGroup.AW, 2);
      case 'ẳ': return make('a', VowelGroup.AW, 3);
      case 'ẵ': return make('a', VowelGroup.AW, 4);
      case 'ặ': return make('a', VowelGroup.AW, 5);

      // â
      case 'â': return make('a', VowelGroup.AA, 0);
      case 'ấ': return make('a', VowelGroup.AA, 1);
      case 'ầ': return make('a', VowelGroup.AA, 2);
      case 'ẩ': return make('a', VowelGroup.AA, 3);
      case 'ẫ': return make('a', VowelGroup.AA, 4);
      case 'ậ': return make('a', VowelGroup.AA, 5);

      // e
      case 'e': return make('e', VowelGroup.E, 0);
      case 'é': return make('e', VowelGroup.E, 1);
      case 'è': return make('e', VowelGroup.E, 2);
      case 'ẻ': return make('e', VowelGroup.E, 3);
      case 'ẽ': return make('e', VowelGroup.E, 4);
      case 'ẹ': return make('e', VowelGroup.E, 5);

      // ê
      case 'ê': return make('e', VowelGroup.EE, 0);
      case 'ế': return make('e', VowelGroup.EE, 1);
      case 'ề': return make('e', VowelGroup.EE, 2);
      case 'ể': return make('e', VowelGroup.EE, 3);
      case 'ễ': return make('e', VowelGroup.EE, 4);
      case 'ệ': return make('e', VowelGroup.EE, 5);

      // i
      case 'i': return make('i', VowelGroup.I, 0);
      case 'í': return make('i', VowelGroup.I, 1);
      case 'ì': return make('i', VowelGroup.I, 2);
      case 'ỉ': return make('i', VowelGroup.I, 3);
      case 'ĩ': return make('i', VowelGroup.I, 4);
      case 'ị': return make('i', VowelGroup.I, 5);

      // o
      case 'o': return make('o', VowelGroup.O, 0);
      case 'ó': return make('o', VowelGroup.O, 1);
      case 'ò': return make('o', VowelGroup.O, 2);
      case 'ỏ': return make('o', VowelGroup.O, 3);
      case 'õ': return make('o', VowelGroup.O, 4);
      case 'ọ': return make('o', VowelGroup.O, 5);

      // ô
      case 'ô': return make('o', VowelGroup.OO, 0);
      case 'ố': return make('o', VowelGroup.OO, 1);
      case 'ồ': return make('o', VowelGroup.OO, 2);
      case 'ổ': return make('o', VowelGroup.OO, 3);
      case 'ỗ': return make('o', VowelGroup.OO, 4);
      case 'ộ': return make('o', VowelGroup.OO, 5);

      // ơ
      case 'ơ': return make('o', VowelGroup.OW, 0);
      case 'ớ': return make('o', VowelGroup.OW, 1);
      case 'ờ': return make('o', VowelGroup.OW, 2);
      case 'ở': return make('o', VowelGroup.OW, 3);
      case 'ỡ': return make('o', VowelGroup.OW, 4);
      case 'ợ': return make('o', VowelGroup.OW, 5);

      // u
      case 'u': return make('u', VowelGroup.U, 0);
      case 'ú': return make('u', VowelGroup.U, 1);
      case 'ù': return make('u', VowelGroup.U, 2);
      case 'ủ': return make('u', VowelGroup.U, 3);
      case 'ũ': return make('u', VowelGroup.U, 4);
      case 'ụ': return make('u', VowelGroup.U, 5);

      // ư
      case 'ư': return make('u', VowelGroup.UW, 0);
      case 'ứ': return make('u', VowelGroup.UW, 1);
      case 'ừ': return make('u', VowelGroup.UW, 2);
      case 'ử': return make('u', VowelGroup.UW, 3);
      case 'ữ': return make('u', VowelGroup.UW, 4);
      case 'ự': return make('u', VowelGroup.UW, 5);

      // y
      case 'y': return make('y', VowelGroup.Y, 0);
      case 'ý': return make('y', VowelGroup.Y, 1);
      case 'ỳ': return make('y', VowelGroup.Y, 2);
      case 'ỷ': return make('y', VowelGroup.Y, 3);
      case 'ỹ': return make('y', VowelGroup.Y, 4);
      case 'ỵ': return make('y', VowelGroup.Y, 5);

      default:
        return undefined;
    }
  }

  private setTone(ch: string, tone: number): string {
    const info: VowelInfo | undefined = this.getVowelInfo(ch);
    if (!info) return ch;
    const base: string = info.base;
    const group: VowelGroup = info.group;
    const isUpper: boolean = (ch.toUpperCase() === ch);

    const out: string = this.composeVowel(base, group, tone);
    return isUpper ? out.toUpperCase() : out;
  }

  private composeVowel(base: string, group: VowelGroup, tone: number): string {
    const b: string = base.toLowerCase();
    const t: number = tone;

    if (b === 'a') {
      if (group === VowelGroup.A) return ['a', 'á', 'à', 'ả', 'ã', 'ạ'][t];
      if (group === VowelGroup.AW) return ['ă', 'ắ', 'ằ', 'ẳ', 'ẵ', 'ặ'][t];
      if (group === VowelGroup.AA) return ['â', 'ấ', 'ầ', 'ẩ', 'ẫ', 'ậ'][t];
    }

    if (b === 'e') {
      if (group === VowelGroup.E) return ['e', 'é', 'è', 'ẻ', 'ẽ', 'ẹ'][t];
      if (group === VowelGroup.EE) return ['ê', 'ế', 'ề', 'ể', 'ễ', 'ệ'][t];
    }

    if (b === 'i') return ['i', 'í', 'ì', 'ỉ', 'ĩ', 'ị'][t];

    if (b === 'o') {
      if (group === VowelGroup.O) return ['o', 'ó', 'ò', 'ỏ', 'õ', 'ọ'][t];
      if (group === VowelGroup.OO) return ['ô', 'ố', 'ồ', 'ổ', 'ỗ', 'ộ'][t];
      if (group === VowelGroup.OW) return ['ơ', 'ớ', 'ờ', 'ở', 'ỡ', 'ợ'][t];
    }

    if (b === 'u') {
      if (group === VowelGroup.U) return ['u', 'ú', 'ù', 'ủ', 'ũ', 'ụ'][t];
      if (group === VowelGroup.UW) return ['ư', 'ứ', 'ừ', 'ử', 'ữ', 'ự'][t];
    }

    if (b === 'y') return ['y', 'ý', 'ỳ', 'ỷ', 'ỹ', 'ỵ'][t];

    return base;
  }

  // ---------- Apply tone key ----------
  private applyToneKey(word: string, keyChar: string): string {
    const tone: number = this.toneOfKey(keyChar);
    if (tone === 0) return word;

    const chars: Array<string> = word.split('');

    // ✅ lấy cụm nguyên âm CUỐI (fix telex -> telẽ thay vì tẽle)
    const span: VowelSpan | undefined = this.findVowelSpan(chars);
    if (!span) return word;

    let vsi: number = span.start;
    const vei: number = span.end;

    // special case: "qu" và "gi"
    if (vsi + 1 <= vei) {
      const b0: string = this.toBaseLetter(chars[vsi]);

      // skip 'u' after q in "qu"
      if (b0 === 'u' && vsi - 1 >= 0) {
        const prev: string = chars[vsi - 1].toLowerCase();
        if (prev === 'q') {
          vsi = vsi + 1;
        }
      }

      // skip 'i' after g in "gi"
      if (b0 === 'i' && vsi - 1 >= 0) {
        const prev2: string = chars[vsi - 1].toLowerCase();
        if (prev2 === 'g') {
          vsi = vsi + 1;
        }
      }
    }

    const markPos: number = this.findToneMarkPosition(chars, vsi, vei);
    if (markPos < 0) return word;

    const vowelInfo: VowelInfo | undefined = this.getVowelInfo(chars[markPos]);
    if (!vowelInfo) return word;

    // toggle off if same tone
    const isToggleOff: boolean = (vowelInfo.tone === tone);
    chars[markPos] = this.setTone(chars[markPos], isToggleOff ? 0 : tone);

    // ✅ QUAN TRỌNG: nếu bấm tone key lần 2 để bỏ dấu -> append ký tự tone
    // ví dụ: telẽ + x => telex
    if (isToggleOff) {
      return chars.join('') + keyChar;
    }

    return chars.join('');
  }

  // ===== Shape keys: aa/ee/oo and w rules (aw/ow/uw, uow->ươ) =====
  private applyShapeKey(word: string, keyChar: string): string {
    const k: string = keyChar;
    const kl: string = k.toLowerCase();
    const chars: Array<string> = word.split('');
    if (chars.length === 0) return word;

    const lastIdx: number = chars.length - 1;
    const last: string = chars[lastIdx];

    // w: aw/ow/uw toggle, and uo + w <-> ươ
    if (kl === 'w') {
      // uo -> ươ (and toggle back)
      if (chars.length >= 2) {
        const c1: string = chars[chars.length - 2];
        const c2: string = chars[chars.length - 1];
        const b1: string = this.toBaseLetter(c1);
        const b2: string = this.toBaseLetter(c2);

        if (b1 === 'u' && b2 === 'o') {
          const i1: VowelInfo | undefined = this.getVowelInfo(c1);
          const i2: VowelInfo | undefined = this.getVowelInfo(c2);

          if (i1 && i2 && i1.group === VowelGroup.UW && i2.group === VowelGroup.OW) {
            const toneKeep: number = i2.tone;
            const uBase: string = (c1.toUpperCase() === c1) ? 'U' : 'u';
            const oBase: string = (c2.toUpperCase() === c2) ? 'O' : 'o';
            chars[chars.length - 2] = uBase;
            chars[chars.length - 1] = this.setTone(oBase, toneKeep);
            return chars.join('') + k; // toggle OFF + insert typed key
          } else {
            const toneKeep2: number = i2 ? i2.tone : 0;
            const uNew: string = this.composeVowel('u', VowelGroup.UW, 0);
            const oNew: string = this.composeVowel('o', VowelGroup.OW, toneKeep2);
            chars[chars.length - 2] = (c1.toUpperCase() === c1) ? uNew.toUpperCase() : uNew;
            chars[chars.length - 1] = (c2.toUpperCase() === c2) ? oNew.toUpperCase() : oNew;
            return chars.join('');
          }
        }
      }

      // single-letter toggles: a->ă, o->ơ, u->ư (toggle back to base)
      const infoLast: VowelInfo | undefined = this.getVowelInfo(last);
      if (!infoLast) return word;

      const toneKeep3: number = infoLast.tone;
      const isUpper: boolean = (last.toUpperCase() === last);

      // a <-> ă
      if (infoLast.base === 'a') {
        if (infoLast.group === VowelGroup.AW) {
          const aBase: string = isUpper ? 'A' : 'a';
          chars[lastIdx] = this.setTone(aBase, toneKeep3);
          return chars.join('') + k;
        }
        if (infoLast.group === VowelGroup.A) {
          const aw: string = this.composeVowel('a', VowelGroup.AW, toneKeep3);
          chars[lastIdx] = isUpper ? aw.toUpperCase() : aw;
          return chars.join('');
        }
      }

      // o <-> ơ
      if (infoLast.base === 'o') {
        if (infoLast.group === VowelGroup.OW) {
          const oBase2: string = isUpper ? 'O' : 'o';
          chars[lastIdx] = this.setTone(oBase2, toneKeep3);
          return chars.join('') + k;
        }
        if (infoLast.group === VowelGroup.O) {
          const ow: string = this.composeVowel('o', VowelGroup.OW, toneKeep3);
          chars[lastIdx] = isUpper ? ow.toUpperCase() : ow;
          return chars.join('');
        }
      }

      // u <-> ư
      if (infoLast.base === 'u') {
        if (infoLast.group === VowelGroup.UW) {
          const uBase2: string = isUpper ? 'U' : 'u';
          chars[lastIdx] = this.setTone(uBase2, toneKeep3);
          return chars.join('') + k;
        }
        if (infoLast.group === VowelGroup.U) {
          const uw: string = this.composeVowel('u', VowelGroup.UW, toneKeep3);
          chars[lastIdx] = isUpper ? uw.toUpperCase() : uw;
          return chars.join('');
        }
      }

      return word;
    }

    // aa toggle: a <-> â
    if (kl === 'a') {
      const infoLast: VowelInfo | undefined = this.getVowelInfo(last);
      if (!infoLast) return word;

      const toneKeep: number = infoLast.tone;
      const isUpper: boolean = (last.toUpperCase() === last);

      if (infoLast.base === 'a') {
        if (infoLast.group === VowelGroup.AA) {
          const aBase: string = isUpper ? 'A' : 'a';
          chars[lastIdx] = this.setTone(aBase, toneKeep);
          return chars.join('') + k;
        }
        if (infoLast.group === VowelGroup.A) {
          const aa: string = this.composeVowel('a', VowelGroup.AA, toneKeep);
          chars[lastIdx] = isUpper ? aa.toUpperCase() : aa;
          return chars.join('');
        }
      }
      return word;
    }

    // ee toggle: e <-> ê
    if (kl === 'e') {
      const infoLast: VowelInfo | undefined = this.getVowelInfo(last);
      if (!infoLast) return word;

      const toneKeep: number = infoLast.tone;
      const isUpper: boolean = (last.toUpperCase() === last);

      if (infoLast.base === 'e') {
        if (infoLast.group === VowelGroup.EE) {
          const eBase: string = isUpper ? 'E' : 'e';
          chars[lastIdx] = this.setTone(eBase, toneKeep);
          return chars.join('') + k;
        }
        if (infoLast.group === VowelGroup.E) {
          const ee: string = this.composeVowel('e', VowelGroup.EE, toneKeep);
          chars[lastIdx] = isUpper ? ee.toUpperCase() : ee;
          return chars.join('');
        }
      }
      return word;
    }

    // oo toggle: o <-> ô
    if (kl === 'o') {
      const infoLast: VowelInfo | undefined = this.getVowelInfo(last);
      if (!infoLast) return word;

      const toneKeep: number = infoLast.tone;
      const isUpper: boolean = (last.toUpperCase() === last);

      if (infoLast.base === 'o') {
        if (infoLast.group === VowelGroup.OO) {
          const oBase: string = isUpper ? 'O' : 'o';
          chars[lastIdx] = this.setTone(oBase, toneKeep);
          return chars.join('') + k;
        }
        if (infoLast.group === VowelGroup.O) {
          const oo: string = this.composeVowel('o', VowelGroup.OO, toneKeep);
          chars[lastIdx] = isUpper ? oo.toUpperCase() : oo;
          return chars.join('');
        }
      }
      return word;
    }

    return word;
  }

  // ---------- Vowel span & marking rules ----------
  private isVowelChar(ch: string): boolean {
    return this.getVowelInfo(ch) !== undefined;
  }

  // ✅ lấy cụm nguyên âm CUỐI trong word (scan từ phải sang trái)
  private findVowelSpan(chars: Array<string>): VowelSpan | undefined {
    let endIdx: number = -1;
    for (let i = chars.length - 1; i >= 0; i--) {
      if (this.isVowelChar(chars[i])) {
        endIdx = i;
        break;
      }
    }
    if (endIdx < 0) return undefined;

    let startIdx: number = endIdx;
    for (let i = endIdx - 1; i >= 0; i--) {
      if (this.isVowelChar(chars[i])) {
        startIdx = i;
      } else {
        break;
      }
    }

    const span: VowelSpan = new VowelSpan();
    span.start = startIdx;
    span.end = endIdx;
    return span;
  }

  private findToneMarkPosition(chars: Array<string>, vsi: number, vei: number): number {
    if (vsi > vei) return -1;

    // ưu tiên nguyên âm đặc biệt trước
    for (let i = vsi; i <= vei; i++) {
      const info: VowelInfo | undefined = this.getVowelInfo(chars[i]);
      if (info && info.group === VowelGroup.EE) return i; // ê
    }
    for (let i = vsi; i <= vei; i++) {
      const info: VowelInfo | undefined = this.getVowelInfo(chars[i]);
      if (info && info.group === VowelGroup.AA) return i; // â
    }
    for (let i = vsi; i <= vei; i++) {
      const info: VowelInfo | undefined = this.getVowelInfo(chars[i]);
      if (info && info.group === VowelGroup.AW) return i; // ă
    }
    for (let i = vsi; i <= vei; i++) {
      const info: VowelInfo | undefined = this.getVowelInfo(chars[i]);
      if (info && info.group === VowelGroup.UW) return i; // ư
    }
    for (let i = vsi; i <= vei; i++) {
      const info: VowelInfo | undefined = this.getVowelInfo(chars[i]);
      if (info && info.group === VowelGroup.OW) return i; // ơ
    }
    for (let i = vsi; i <= vei; i++) {
      const info: VowelInfo | undefined = this.getVowelInfo(chars[i]);
      if (info && info.group === VowelGroup.OO) return i; // ô
    }

    return this.modernOrthography
      ? this.pickModern(chars, vsi, vei)
      : this.pickOld(vsi, vei);
  }

  private pickOld(vsi: number, vei: number): number {
    let pos: number = vsi;
    const count: number = vei - vsi + 1;
    if (count >= 3) pos = Math.min(vsi + 1, vei);
    return pos;
  }

  private pickModern(chars: Array<string>, vsi: number, vei: number): number {
    const count: number = vei - vsi + 1;

    const b0: string = this.toBaseLetter(chars[vsi]);
    const b1: string = (vsi + 1 <= vei) ? this.toBaseLetter(chars[vsi + 1]) : '';
    const b2: string = (vsi + 2 <= vei) ? this.toBaseLetter(chars[vsi + 2]) : '';

    let pos: number = vei;

    if (count === 3) {
      const p: string = b0 + b1 + b2;
      if (p === 'oai' || p === 'uyu' || p === 'oeo' || p === 'uya') {
        pos = vsi + 1;
      } else {
        pos = vei;
      }
      return pos;
    }

    if (count === 2) {
      if ((b0 === 'o' && (b1 === 'a' || b1 === 'e')) || (b0 === 'u' && b1 === 'y')) {
        pos = vsi + 1;
      }
      if (b0 === 'u' && b1 === 'o') {
        pos = vsi + 1;
      }
      if (b0 === 'i' && (b1 === 'a' || b1 === 'u' || b1 === 'o')) {
        pos = vsi;
      }
      if (b0 === 'u' && b1 === 'a') {
        pos = vsi;
      }
      return pos;
    }

    return vsi;
  }
}
