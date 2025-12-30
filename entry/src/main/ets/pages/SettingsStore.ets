import preferences from '@ohos.data.preferences';

export const PREF_NAME: string = 'vk_settings_app';

export const KEYBOARD_HEIGHT_VP: string = 'keyboard_height_vp';
export const DEFAULT_KEYBOARD_HEIGHT_VP: number = 240;

export const MIN_KEYBOARD_HEIGHT_VP: number = 200;
export const MAX_KEYBOARD_HEIGHT_VP: number = 320;

export const KEYBOARD_RELOAD_SEQ: string = 'keyboard_reload_seq';

// input method: 'telex' | 'vni'
export const INPUT_METHOD: string = 'input_method';

// number row on/off
export const NUMBER_ROW_ENABLED: string = 'number_row_enabled';
export const DEFAULT_NUMBER_ROW_ENABLED: boolean = true;

// Haptic feedback (vibration on key press)
export const KEY_HAPTIC_ENABLED: string = 'haptic_enabled';
export const DEFAULT_HAPTIC_ENABLED: boolean = true;
export const KEY_HAPTIC_INTENSITY: string = 'haptic_intensity';
// 0..100 (relative)
export const DEFAULT_HAPTIC_INTENSITY: number = 60;

export type InputMethodType = 'telex' | 'vni';

function toNumber(v: number | string | boolean | undefined, fallback: number): number {
  if (v === undefined || v === null) return fallback;
  if (typeof v === 'number') return v;
  if (typeof v === 'boolean') return v ? 1 : 0;

  const s: string = String(v);
  const m = s.match(/-?\d+(\.\d+)?/);
  if (m && m[0]) return Number(m[0]);
  return fallback;
}

function toBool(v: number | string | boolean | undefined, fallback: boolean): boolean {
  if (v === undefined || v === null) return fallback;
  if (typeof v === 'boolean') return v;
  if (typeof v === 'number') return v !== 0;

  const s: string = String(v).trim().toLowerCase();
  if (s === 'true' || s === '1' || s === 'yes' || s === 'on') return true;
  if (s === 'false' || s === '0' || s === 'no' || s === 'off') return false;
  return fallback;
}

export function clampKeyboardHeightVp(v: number): number {
  let n: number = Math.round(v);
  if (!isFinite(n)) return DEFAULT_KEYBOARD_HEIGHT_VP;
  if (n < MIN_KEYBOARD_HEIGHT_VP) n = MIN_KEYBOARD_HEIGHT_VP;
  if (n > MAX_KEYBOARD_HEIGHT_VP) n = MAX_KEYBOARD_HEIGHT_VP;
  return n;
}

export function clampHapticIntensity(v: number): number {
  let n: number = Math.round(v);
  if (!isFinite(n)) return DEFAULT_HAPTIC_INTENSITY;
  if (n < 0) n = 0;
  if (n > 100) n = 100;
  return n;
}

// NOTE: using object for context to avoid importing UIAbilityContext types
export async function readKeyboardHeightVp(context: object): Promise<number> {
  try {
    const pref = await preferences.getPreferences(context as never, PREF_NAME);
    const raw: number | string | boolean = (await pref.get(KEYBOARD_HEIGHT_VP, DEFAULT_KEYBOARD_HEIGHT_VP)) as number | string | boolean;
    return clampKeyboardHeightVp(toNumber(raw, DEFAULT_KEYBOARD_HEIGHT_VP));
  } catch {
    return DEFAULT_KEYBOARD_HEIGHT_VP;
  }
}

export async function writeKeyboardHeightVp(context: object, heightVp: number): Promise<void> {
  try {
    const pref = await preferences.getPreferences(context as never, PREF_NAME);
    const v: number = clampKeyboardHeightVp(heightVp);
    try { pref.put(KEYBOARD_HEIGHT_VP, v); } catch { /* ignore */ }
    try { await pref.flush(); } catch { /* ignore */ }
  } catch {
    // ignore
  }
}

export async function bumpKeyboardReloadSeq(context: object): Promise<number> {
  try {
    const pref = await preferences.getPreferences(context as never, PREF_NAME);
    const raw: number | string | boolean = (await pref.get(KEYBOARD_RELOAD_SEQ, 0)) as number | string | boolean;
    const cur: number = toNumber(raw, 0);
    const next: number = cur + 1;
    try { pref.put(KEYBOARD_RELOAD_SEQ, next); } catch { /* ignore */ }
    try { await pref.flush(); } catch { /* ignore */ }
    return next;
  } catch {
    return 0;
  }
}

export async function readKeyboardReloadSeq(context: object): Promise<number> {
  try {
    const pref = await preferences.getPreferences(context as never, PREF_NAME);
    const raw: number | string | boolean = (await pref.get(KEYBOARD_RELOAD_SEQ, 0)) as number | string | boolean;
    return toNumber(raw, 0);
  } catch {
    return 0;
  }
}

export async function readInputMethod(context: object): Promise<InputMethodType> {
  try {
    const pref = await preferences.getPreferences(context as never, PREF_NAME);
    const raw: number | string | boolean = (await pref.get(INPUT_METHOD, 'telex')) as number | string | boolean;
    const s: string = String(raw).toLowerCase();
    if (s === 'vni') return 'vni';
    return 'telex';
  } catch {
    return 'telex';
  }
}

export async function writeInputMethod(context: object, method: InputMethodType): Promise<void> {
  try {
    const pref = await preferences.getPreferences(context as never, PREF_NAME);
    const v: string = method === 'vni' ? 'vni' : 'telex';
    try { pref.put(INPUT_METHOD, v); } catch { /* ignore */ }
    try { await pref.flush(); } catch { /* ignore */ }
  } catch {
    // ignore
  }
}

export async function readNumberRowEnabled(context: object): Promise<boolean> {
  try {
    const pref = await preferences.getPreferences(context as never, PREF_NAME);
    const raw: number | string | boolean = (await pref.get(NUMBER_ROW_ENABLED, DEFAULT_NUMBER_ROW_ENABLED)) as number | string | boolean;
    return toBool(raw, DEFAULT_NUMBER_ROW_ENABLED);
  } catch {
    return DEFAULT_NUMBER_ROW_ENABLED;
  }
}

export async function writeNumberRowEnabled(context: object, enabled: boolean): Promise<void> {
  try {
    const pref = await preferences.getPreferences(context as never, PREF_NAME);
    const v: boolean = !!enabled;
    try { pref.put(NUMBER_ROW_ENABLED, v); } catch { /* ignore */ }
    try { await pref.flush(); } catch { /* ignore */ }
  } catch {
    // ignore
  }
}

export async function readHapticEnabled(context: object): Promise<boolean> {
  try {
    const pref = await preferences.getPreferences(context as never, PREF_NAME);
    const raw: number | string | boolean = (await pref.get(
      KEY_HAPTIC_ENABLED,
      DEFAULT_HAPTIC_ENABLED
    )) as number | string | boolean;
    return toBool(raw, DEFAULT_HAPTIC_ENABLED);
  } catch {
    return DEFAULT_HAPTIC_ENABLED;
  }
}

export async function writeHapticEnabled(context: object, enabled: boolean): Promise<void> {
  try {
    const pref = await preferences.getPreferences(context as never, PREF_NAME);
    const v: boolean = !!enabled;
    try { pref.put(KEY_HAPTIC_ENABLED, v); } catch { /* ignore */ }
    try { await pref.flush(); } catch { /* ignore */ }
  } catch {
    // ignore
  }
}

export async function readHapticIntensity(context: object): Promise<number> {
  try {
    const pref = await preferences.getPreferences(context as never, PREF_NAME);
    const raw: number | string | boolean = (await pref.get(
      KEY_HAPTIC_INTENSITY,
      DEFAULT_HAPTIC_INTENSITY
    )) as number | string | boolean;
    return clampHapticIntensity(toNumber(raw, DEFAULT_HAPTIC_INTENSITY));
  } catch {
    return DEFAULT_HAPTIC_INTENSITY;
  }
}

export async function writeHapticIntensity(context: object, intensity: number): Promise<void> {
  try {
    const pref = await preferences.getPreferences(context as never, PREF_NAME);
    const v: number = clampHapticIntensity(intensity);
    try { pref.put(KEY_HAPTIC_INTENSITY, v); } catch { /* ignore */ }
    try { await pref.flush(); } catch { /* ignore */ }
  } catch {
    // ignore
  }
}
