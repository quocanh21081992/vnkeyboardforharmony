// entry/src/main/ets/InputMethodExtensionAbility/model/TelexEngine.ets
// Telex rules inspired by OpenKey (modern orthography + qu/gi handling + z removes tone).

enum VowelGroup {
  A = 0,   // a
  AW = 1,  // ă
  AA = 2,  // â
  E = 3,   // e
  EE = 4,  // ê
  I = 5,   // i
  O = 6,   // o
  OO = 7,  // ô
  OW = 8,  // ơ
  U = 9,   // u
  UW = 10, // ư
  Y = 11   // y
}

class VowelInfo {
  group: VowelGroup = VowelGroup.A;
  tone: number = 0; // 0..5
  isUpper: boolean = false;
}

export enum TelexActionKind {
  Append = 0,   // insert typed key
  Replace = 1   // replace current composing word with newWord (key consumed)
}

export class TelexApplyResult {
  kind: TelexActionKind = TelexActionKind.Append;
  newWord: string = '';
}

export class TelexEngine {
  // Like OpenKey "Modern orthography":
  // đặt dấu oà/uý thay vì òa/úy
  private readonly modernOrthography: boolean;

  // Optional feature like OpenKey (cc=ch, gg=gi, kk=kh, nn=ng, qq=qu, pp=ph, tt=th)
  private readonly quickTelex: boolean;

  private readonly vowelLower: Array<Array<string>> = [
    ['a', 'á', 'à', 'ả', 'ã', 'ạ'],
    ['ă', 'ắ', 'ằ', 'ẳ', 'ẵ', 'ặ'],
    ['â', 'ấ', 'ầ', 'ẩ', 'ẫ', 'ậ'],
    ['e', 'é', 'è', 'ẻ', 'ẽ', 'ẹ'],
    ['ê', 'ế', 'ề', 'ể', 'ễ', 'ệ'],
    ['i', 'í', 'ì', 'ỉ', 'ĩ', 'ị'],
    ['o', 'ó', 'ò', 'ỏ', 'õ', 'ọ'],
    ['ô', 'ố', 'ồ', 'ổ', 'ỗ', 'ộ'],
    ['ơ', 'ớ', 'ờ', 'ở', 'ỡ', 'ợ'],
    ['u', 'ú', 'ù', 'ủ', 'ũ', 'ụ'],
    ['ư', 'ứ', 'ừ', 'ử', 'ữ', 'ự'],
    ['y', 'ý', 'ỳ', 'ỷ', 'ỹ', 'ỵ']
  ];

  private readonly vowelUpper: Array<Array<string>> = [];
  private readonly vowelMap: Map<string, VowelInfo> = new Map<string, VowelInfo>();

  // base letter for mark-position rules
  private readonly baseOfGroup: Array<string> = [
    'a', 'a', 'a', 'e', 'e', 'i', 'o', 'o', 'o', 'u', 'u', 'y'
  ];

  constructor(modernOrthography: boolean = true, quickTelex: boolean = false) {
    this.modernOrthography = modernOrthography;
    this.quickTelex = quickTelex;

    // build upper tables + lookup map
    for (let g = 0; g < this.vowelLower.length; g++) {
      const rowLower: Array<string> = this.vowelLower[g];
      const rowUpper: Array<string> = [];
      for (let t = 0; t < rowLower.length; t++) {
        rowUpper.push(rowLower[t].toUpperCase());
      }
      this.vowelUpper.push(rowUpper);

      for (let t = 0; t < rowLower.length; t++) {
        const li: VowelInfo = new VowelInfo();
        li.group = g as VowelGroup;
        li.tone = t;
        li.isUpper = false;
        this.vowelMap.set(rowLower[t], li);

        const ui: VowelInfo = new VowelInfo();
        ui.group = g as VowelGroup;
        ui.tone = t;
        ui.isUpper = true;
        this.vowelMap.set(rowUpper[t], ui);
      }
    }
  }

  apply(word: string, keyChar: string): TelexApplyResult {
    const res: TelexApplyResult = new TelexApplyResult();
    res.newWord = word;

    if (keyChar.length !== 1) {
      res.kind = TelexActionKind.Append;
      return res;
    }

    const k: string = keyChar;
    const kl: string = k.toLowerCase();

    // Only process letters (basic a-z). Anything else: append normally.
    if (!this.isAsciiLetter(kl)) {
      res.kind = TelexActionKind.Append;
      return res;
    }

    // QuickTelex (optional): cc=ch, gg=gi, kk=kh, nn=ng, qq=qu, pp=ph, tt=th
    if (this.quickTelex && word.length > 0) {
      const last: string = word.charAt(word.length - 1);
      if (last.toLowerCase() === kl) {
        const rep: string = this.quickTelexReplace(kl, this.isUpperLike(last, k));
        if (rep.length > 0) {
          res.kind = TelexActionKind.Replace;
          res.newWord = word.slice(0, word.length - 1) + rep;
          return res;
        }
      }
    }

    // z: remove tone mark (OpenKey behavior: if nothing changed -> type 'z')
    if (kl === 'z') {
      const removed: string = this.removeToneInWord(word);
      if (removed !== word) {
        res.kind = TelexActionKind.Replace;
        res.newWord = removed;
      } else {
        res.kind = TelexActionKind.Append;
      }
      return res;
    }

    // dd <-> đ
    if (kl === 'd') {
      const toggled: string = this.toggleD(word, k);
      if (toggled !== word) {
        res.kind = TelexActionKind.Replace;
        res.newWord = toggled;
      } else {
        res.kind = TelexActionKind.Append;
      }
      return res;
    }

    // vowel-shape keys (aa/ee/oo and w rules)
    if (kl === 'a' || kl === 'e' || kl === 'o' || kl === 'w') {
      const shaped: string = this.applyShapeKey(word, k);
      if (shaped !== word) {
        res.kind = TelexActionKind.Replace;
        res.newWord = shaped;
      } else {
        // cannot shape -> type literal
        res.kind = TelexActionKind.Append;
      }
      return res;
    }

    // tone keys: s f r x j
    if (kl === 's' || kl === 'f' || kl === 'r' || kl === 'x' || kl === 'j') {
      const toned: string = this.applyToneKey(word, kl);
      if (toned !== word) {
        res.kind = TelexActionKind.Replace;
        res.newWord = toned;
      } else {
        // no vowel to place tone -> type literal (OpenKey does that)
        res.kind = TelexActionKind.Append;
      }
      return res;
    }

    // default: type literal char
    res.kind = TelexActionKind.Append;
    return res;
  }

  private isAsciiLetter(c: string): boolean {
    const code: number = c.charCodeAt(0);
    return code >= 97 && code <= 122;
  }

  private isUpperLike(a: string, b: string): boolean {
    return (a === a.toUpperCase()) || (b === b.toUpperCase());
  }

  private quickTelexReplace(kl: string, upper: boolean): string {
    let rep: string = '';
    switch (kl) {
      case 'c': rep = 'ch'; break;
      case 'g': rep = 'gi'; break;
      case 'k': rep = 'kh'; break;
      case 'n': rep = 'ng'; break;
      case 'q': rep = 'qu'; break;
      case 'p': rep = 'ph'; break;
      case 't': rep = 'th'; break;
      default: rep = ''; break;
    }
    return upper ? rep.toUpperCase() : rep;
  }

  private getVowelInfo(ch: string): VowelInfo | undefined {
    return this.vowelMap.get(ch);
  }

  private toBaseLetter(ch: string): string {
    const info: VowelInfo | undefined = this.getVowelInfo(ch);
    if (!info) return ch.toLowerCase();
    return this.baseOfGroup[info.group];
  }

  private isVowel(ch: string): boolean {
    return this.vowelMap.has(ch);
  }

  private charFrom(group: VowelGroup, tone: number, upper: boolean): string {
    const t: number = Math.max(0, Math.min(5, tone));
    return upper ? this.vowelUpper[group][t] : this.vowelLower[group][t];
  }

  private convertVowelGroupKeepTone(ch: string, target: VowelGroup): string {
    const info: VowelInfo | undefined = this.getVowelInfo(ch);
    if (!info) return ch;
    return this.charFrom(target, info.tone, info.isUpper);
  }

  private setTone(ch: string, tone: number): string {
    const info: VowelInfo | undefined = this.getVowelInfo(ch);
    if (!info) return ch;
    return this.charFrom(info.group, tone, info.isUpper);
  }

  private removeToneChar(ch: string): string {
    return this.setTone(ch, 0);
  }

  // ===== Z key: remove tone on vowel cluster (keep â/ă/ê/ô/ơ/ư) =====
  private removeToneInWord(word: string): string {
    const chars: Array<string> = word.split('');
    const range: Array<number> = this.findVowelClusterRange(chars);
    if (range.length !== 2) return word;

    const vsi: number = range[0];
    const vei: number = range[1];

    let changed: boolean = false;
    for (let i = vsi; i <= vei; i++) {
      if (this.isVowel(chars[i])) {
        const before: string = chars[i];
        const after: string = this.removeToneChar(before);
        if (after !== before) {
          chars[i] = after;
          changed = true;
        }
      }
    }
    return changed ? chars.join('') : word;
  }

  // ===== Tone keys s f r x j =====
  private toneIndexFromKey(tk: string): number {
    // 1:sắc 2:huyền 3:hỏi 4:ngã 5:nặng
    switch (tk) {
      case 's': return 1;
      case 'f': return 2;
      case 'r': return 3;
      case 'x': return 4;
      case 'j': return 5;
      default: return 0;
    }
  }

  private applyToneKey(word: string, toneKeyLower: string): string {
    const chars: Array<string> = word.split('');
    const range: Array<number> = this.findVowelClusterRange(chars);
    if (range.length !== 2) return word;

    const vsi: number = range[0];
    const vei: number = range[1];

    const markPos: number = this.pickTonePosition(chars, vsi, vei);
    if (markPos < 0) return word;

    const vinfo: VowelInfo | undefined = this.getVowelInfo(chars[markPos]);
    if (!vinfo) return word;

    const tone: number = this.toneIndexFromKey(toneKeyLower);
    const isToggleOff: boolean = (vinfo.tone === tone);
    chars[markPos] = this.setTone(chars[markPos], isToggleOff ? 0 : tone);

    return chars.join('');
  }

  // ===== Shape keys: aa/ee/oo and w rules (aw/ow/uw, uow->ươ) =====
  private applyShapeKey(word: string, keyChar: string): string {
    const k: string = keyChar;
    const kl: string = k.toLowerCase();
    const chars: Array<string> = word.split('');
    if (chars.length === 0) return word;

    // Helper
    const lastIdx: number = chars.length - 1;
    const last: string = chars[lastIdx];
    const lastLower: string = last.toLowerCase();

    // w: aw/ow/uw toggle, and uo + w <-> ươ
    if (kl === 'w') {
      // uo -> ươ (and toggle back)
      if (chars.length >= 2) {
        const c1: string = chars[chars.length - 2];
        const c2: string = chars[chars.length - 1];
        const b1: string = this.toBaseLetter(c1);
        const b2: string = this.toBaseLetter(c2);

        if (b1 === 'u' && b2 === 'o') {
          // toggle: if already ư + ơ -> back to u + o (keep tone)
          const i1: VowelInfo | undefined = this.getVowelInfo(c1);
          const i2: VowelInfo | undefined = this.getVowelInfo(c2);
          if (i1 && i2) {
            const isHorned: boolean =
              (i1.group === VowelGroup.UW) && (i2.group === VowelGroup.OW);

            chars[chars.length - 2] = isHorned
              ? this.convertVowelGroupKeepTone(c1, VowelGroup.U)
              : this.convertVowelGroupKeepTone(c1, VowelGroup.UW);

            chars[chars.length - 1] = isHorned
              ? this.convertVowelGroupKeepTone(c2, VowelGroup.O)
              : this.convertVowelGroupKeepTone(c2, VowelGroup.OW);

            return chars.join('');
          }
        }
      }

      // single-letter toggles: a<->ă, o<->ơ, u<->ư
      if (this.isVowel(last)) {
        const info: VowelInfo | undefined = this.getVowelInfo(last);
        if (!info) return word;

        // base letter decides
        const base: string = this.baseOfGroup[info.group];

        if (base === 'a') {
          const to: VowelGroup = (info.group === VowelGroup.AW) ? VowelGroup.A : VowelGroup.AW;
          chars[lastIdx] = this.convertVowelGroupKeepTone(last, to);
          return chars.join('');
        }
        if (base === 'o') {
          const to: VowelGroup = (info.group === VowelGroup.OW) ? VowelGroup.O : VowelGroup.OW;
          chars[lastIdx] = this.convertVowelGroupKeepTone(last, to);
          return chars.join('');
        }
        if (base === 'u') {
          const to: VowelGroup = (info.group === VowelGroup.UW) ? VowelGroup.U : VowelGroup.UW;
          chars[lastIdx] = this.convertVowelGroupKeepTone(last, to);
          return chars.join('');
        }
      }
      return word;
    }

    // aa: a <-> â (keep tone)
    if (kl === 'a') {
      if (this.isVowel(last) && this.toBaseLetter(last) === 'a') {
        const info: VowelInfo | undefined = this.getVowelInfo(last);
        if (!info) return word;

        // toggle a <-> â (OpenKey: same key a toggles ^ on 'a')
        const to: VowelGroup = (info.group === VowelGroup.AA) ? VowelGroup.A : VowelGroup.AA;
        chars[lastIdx] = this.convertVowelGroupKeepTone(last, to);
        return chars.join('');
      }
      return word;
    }

    // ee: e <-> ê
    if (kl === 'e') {
      if (this.isVowel(last) && this.toBaseLetter(last) === 'e') {
        const info: VowelInfo | undefined = this.getVowelInfo(last);
        if (!info) return word;
        const to: VowelGroup = (info.group === VowelGroup.EE) ? VowelGroup.E : VowelGroup.EE;
        chars[lastIdx] = this.convertVowelGroupKeepTone(last, to);
        return chars.join('');
      }
      return word;
    }

    // oo: o <-> ô
    if (kl === 'o') {
      if (this.isVowel(last) && this.toBaseLetter(last) === 'o') {
        const info: VowelInfo | undefined = this.getVowelInfo(last);
        if (!info) return word;
        const to: VowelGroup = (info.group === VowelGroup.OO) ? VowelGroup.O : VowelGroup.OO;
        chars[lastIdx] = this.convertVowelGroupKeepTone(last, to);
        return chars.join('');
      }
      return word;
    }

    return word;
  }

  // ===== dd <-> đ (OpenKey style toggle on previous 'd') =====
  private toggleD(word: string, typedChar: string): string {
    const chars: Array<string> = word.split('');
    if (chars.length === 0) return word;

    const lastIdx: number = chars.length - 1;
    const last: string = chars[lastIdx];
    const lastLower: string = last.toLowerCase();

    // If previous is d -> toggle to đ (keep case)
    if (lastLower === 'd') {
      const upper: boolean = (last === 'D') || (typedChar === 'D');
      chars[lastIdx] = upper ? 'Đ' : 'đ';
      return chars.join('');
    }

    // If previous is đ and type d again -> restore to d (OpenKey toggle)
    if (last === 'đ' || last === 'Đ') {
      const upper: boolean = (last === 'Đ') || (typedChar === 'D');
      chars[lastIdx] = upper ? 'D' : 'd';
      return chars.join('');
    }

    return word; // cannot toggle, let caller append
  }

  // ===== Find vowel cluster like OpenKey findAndCalculateVowel (simplified) =====
  // returns [vsi, vei] or []
  private findVowelClusterRange(chars: Array<string>): Array<number> {
    let vei: number = -1;
    let vsi: number = -1;
    let seenVowel: boolean = false;

    for (let i = chars.length - 1; i >= 0; i--) {
      if (this.isVowel(chars[i])) {
        if (!seenVowel) {
          vei = i;
          seenVowel = true;
        }
        vsi = i;
      } else {
        if (seenVowel) break;
      }
    }

    if (!seenVowel || vsi < 0 || vei < 0) return [];

    // exclude "u" in "qu"
    if (vsi - 1 >= 0) {
      const prev: string = chars[vsi - 1].toLowerCase();
      const curBase: string = this.toBaseLetter(chars[vsi]);
      if (prev === 'q' && curBase === 'u') {
        vsi = vsi + 1;
      }
    }

    // exclude "i" in "gi"
    if (vsi - 1 >= 0) {
      const prev2: string = chars[vsi - 1].toLowerCase();
      const curBase2: string = this.toBaseLetter(chars[vsi]);
      if (prev2 === 'g' && curBase2 === 'i') {
        vsi = vsi + 1;
      }
    }

    if (vsi > vei) return [];
    return [vsi, vei];
  }

  private pickTonePosition(chars: Array<string>, vsi: number, vei: number): number {
    const count: number = vei - vsi + 1;
    if (count <= 0) return -1;
    if (count === 1) return vei;

    // Prefer ê or ơ or ô inside cluster (OpenKey style)
    for (let i = vsi; i <= vei; i++) {
      const info: VowelInfo | undefined = this.getVowelInfo(chars[i]);
      if (!info) continue;
      if (info.group === VowelGroup.EE) return i; // ê
    }
    for (let i = vsi; i <= vei; i++) {
      const info: VowelInfo | undefined = this.getVowelInfo(chars[i]);
      if (!info) continue;
      if (info.group === VowelGroup.OW) return i; // ơ
    }
    for (let i = vsi; i <= vei; i++) {
      const info: VowelInfo | undefined = this.getVowelInfo(chars[i]);
      if (!info) continue;
      if (info.group === VowelGroup.OO) return i; // ô
    }

    // modern vs old
    return this.modernOrthography
      ? this.pickModern(chars, vsi, vei)
      : this.pickOld(chars, vsi, vei);
  }

  // Approx from OpenKey handleOldMark: tends to mark earlier vowel
  private pickOld(chars: Array<string>, vsi: number, vei: number): number {
    // default: first vowel
    let pos: number = vsi;

    // if 3 vowels OR can end with consonant -> second vowel (OpenKey rule 2)
    const count: number = vei - vsi + 1;
    if (count >= 3) {
      pos = Math.min(vsi + 1, vei);
    }

    // if cluster contains ê/ơ already handled earlier
    return pos;
  }

  // Approx from OpenKey handleModernMark: tends to mark later vowel (oà/uý style)
  private pickModern(chars: Array<string>, vsi: number, vei: number): number {
    const count: number = vei - vsi + 1;

    const b0: string = this.toBaseLetter(chars[vsi]);
    const b1: string = (vsi + 1 <= vei) ? this.toBaseLetter(chars[vsi + 1]) : '';
    const b2: string = (vsi + 2 <= vei) ? this.toBaseLetter(chars[vsi + 2]) : '';

    let pos: number = vei; // default

    // OpenKey-like rule set (simplified but practical)
    if (count === 3) {
      const p: string = b0 + b1 + b2;
      if (p === 'oai' || p === 'uyu' || p === 'oeo' || p === 'uya') {
        pos = vsi + 1;
      }
    }

    if (count === 2) {
      const p2: string = b0 + b1;

      // oi/ai/ui => first vowel
      if (p2 === 'oi' || p2 === 'ai' || p2 === 'ui') {
        pos = vsi;
      }

      // ay => a
      if (b0 === 'a' && b1 === 'y') {
        pos = vsi;
      }

      // uo => second vowel (ươ -> ơ)
      if (b0 === 'u' && b1 === 'o') {
        pos = vsi + 1;
      }

      // ia/iu/io: usually mark i, except "gi" handled by vsi shift already
      if (b0 === 'i' && (b1 === 'a' || b1 === 'u' || b1 === 'o')) {
        pos = vsi;
      }

      // ua: mark u unless it's "qu" (handled by vsi shift)
      if (b0 === 'u' && b1 === 'a') {
        pos = vsi;
      }

      // oo -> last
      if (p2 === 'oo') {
        pos = vei;
      }
    }

    // With 3 vowels and many cases, OpenKey often marks middle
    if (count >= 3) {
      // default middle for safety
      pos = Math.min(vsi + 1, vei);
    }

    // also: if second vowel is o/u, OpenKey tends to put mark on previous (vei-1)
    if (count >= 2 && (b1 === 'o' || b1 === 'u')) {
      pos = Math.max(vsi, vei - 1);
    }

    return Math.max(vsi, Math.min(vei, pos));
  }
}
