#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
《美少女梦工厂4 完璧版》(Princess Maker 4 Perfect Edition) 文本与剧情对话完整解密提取脚本（简体中文版）
支持：
1. GCAX (GflGCACryptograph, 密钥 "kf") 加密封包解密与解包 (PrincessMaker4+/script 与 PM4Omake/script)
2. G2CD0461 (.g2) 与 G2MM0461 (.g2m) 虚拟机字节码反编译与字符串解密
3. 完整还原说话人姓名、语音文件编号、多段拼接台词、表情立绘状态、分支选项及跳转标签
4. 自动转换为简体中文，并将女儿默认名“派翠西亚”与姓氏“海斯”替换为玩家自定义占位符 {daughter_name} 与 {secondname}
"""

import os
import re
import json
import zlib
import struct
import ctypes
from collections import defaultdict

# ==============================================================================
# 0. 繁体转简体与自定义女儿姓名替换工具
# ==============================================================================

_kernel32 = ctypes.windll.kernel32
_LCMAP_SIMPLIFIED_CHINESE = 0x02000000

_POST_SIMP_CHAR_MAP = str.maketrans({
    "麽": "么",
    "麼": "么",
    "後": "后",
    "乾": "干",
    "於": "于",
    "牠": "它",
    "祂": "他",
    "姊": "姐",
    "徵": "征",
    "夥": "伙",
    "昇": "升",
    "慾": "欲",
    "敎": "教",
    "搥": "捶",
    "暪": "瞒",
    "嚐": "尝",
    "蹟": "迹",
    "勳": "勋",
    "衆": "众",
    "跘": "绊",
    "帰": "归",
    "黒": "黑",
    "姫": "姬",
    "団": "团",
    "戦": "战",
    "搧": "扇",
    "癒": "愈",
    "搾": "榨",
    "沈": "沉",
})

_WORD_REPLACEMENTS = [
    ("彷彿", "仿佛"),
    ("藉口", "借口"),
    ("藉此", "借此"),
    ("修链", "修炼"),
    ("锻链", "锻炼"),
    ("试链", "试炼"),
    ("链金", "炼金"),
    ("计画", "计划"),
    ("偶而", "偶尔"),
    ("倒大楣", "倒大霉"),
    ("凯依", "凯伊"),
    ("克莉丝汀娜", "克莉丝提娜"),
    ("玛莉", "玛丽"),
    ("派翠西亚", "{daughter_name}"),
    ("派翠西亞", "{daughter_name}"),
]


def to_simplified_chinese(text: str) -> str:
    """将繁体中文文本转换为标准简体中文，并替换女儿默认名为 {daughter_name}"""
    if not text:
        return text
    # 预处理避免 LCMapStringW 将“囉”合并为“罗”
    s = text.replace("囉", "啰").replace("派翠西亞", "{daughter_name}")
    buf_len = len(s) + 16
    buf = ctypes.create_unicode_buffer(buf_len)
    res = _kernel32.LCMapStringW(0x0804, _LCMAP_SIMPLIFIED_CHINESE, s, len(s), buf, buf_len)
    if res > 0:
        s = buf.value[:res]
    s = s.translate(_POST_SIMP_CHAR_MAP)
    for old, new in _WORD_REPLACEMENTS:
        s = s.replace(old, new)
    return s


# ==============================================================================
# 1. GCAX (GflGCACryptograph) 封包解密算法
# ==============================================================================

class MT19937:
    def __init__(self):
        self.mt = [0] * 624
        self.mt_tempered = [0] * 624
        self.index = 0

    def twist(self):
        mt = self.mt
        tempered = self.mt_tempered
        for i in range(624):
            y = (mt[i] & 0x80000000) | (mt[(i + 1) % 624] & 0x7fffffff)
            mt[i] = mt[(i + 397) % 624] ^ (y >> 1) ^ (0x9908b0df if (y & 1) else 0)
        for i in range(624):
            y = mt[i]
            y ^= (y >> 11)
            y ^= (y << 7) & 0x9d2c5680
            y ^= (y << 15) & 0xefc60000
            y ^= (y >> 18)
            tempered[i] = y & 0xffffffff
        self.index = 0

    def set_key_array(self, arr):
        n = len(arr)
        for i in range(624):
            self.mt[i] = arr[i % n] & 0xffffffff
        self.twist()


class GflGCACryptograph:
    """还原自 PrincessMaker4+.exe (0x4e4200 - 0x4e8800) 的自定义 MT19937 流密码"""
    def __init__(self, key_bytes: bytes):
        self.mt = MT19937()
        self.set_key(key_bytes)

    def set_key(self, key_bytes: bytes):
        buf = [0] * 624
        klen = len(key_bytes)
        if klen > 0:
            for idx in range(klen):
                rem = (idx + 1) % 624
                b = struct.unpack("b", key_bytes[idx:idx+1])[0] & 0xffffffff
                ebp = ((b << 8) | b) & 0xffffffff
                ebp = ((ebp << 16) | ebp) & 0xffffffff
                buf[rem] = (ebp ^ ((buf[rem] << 8) & 0xffffffff)) & 0xffffffff
        edi = min(klen + 1, 624)
        esi = 0x1105
        init_arr = [0] * 624
        for ecx in range(624):
            eax = (esi * 0x10dcd + 1) & 0xffffffff
            edx = esi & 0xffff0000
            esi_val = edx | (eax >> 16)
            esi = (eax * 0x10dcd + 1) & 0xffffffff
            init_arr[ecx] = (esi_val ^ buf[ecx % edi]) & 0xffffffff
        self.mt.set_key_array(init_arr)

    def decrypt(self, data: bytes) -> bytes:
        n = len(data)
        num_words = (n + 3) // 4
        mt = self.mt
        tempered = mt.mt_tempered
        idx = mt.index
        xor_words = [0] * num_words
        for w_i in range(num_words):
            if idx >= 624:
                mt.twist()
                idx = 0
            w0, w1, w2, w3, w4, w5, w6, w7 = tempered[idx:idx+8]
            idx += 8

            ecx = w3 ^ w1
            ecx ^= (ecx >> 16)
            rot1 = ((ecx >> 8) ^ ecx) & 0x1f
            eax = w2 ^ w0
            edi1 = ((eax >> (32 - rot1)) | ((eax << rot1) & 0xffffffff)) & 0xffffffff

            ecx2 = w7 ^ w5
            ecx2 ^= (ecx2 >> 16)
            rot2 = ((ecx2 >> 8) ^ ecx2) & 0x1f
            eax2 = w6 ^ w4
            edi2 = ((eax2 >> (32 - rot2)) | ((eax2 << rot2) & 0xffffffff)) & 0xffffffff

            xor_words[w_i] = (edi1 ^ edi2) & 0xffffffff
        mt.index = idx

        keystream = struct.pack(f"<{num_words}I", *xor_words)[:n]
        return (int.from_bytes(data, "little") ^ int.from_bytes(keystream, "little")).to_bytes(n, "little")


def unpack_gcax_archive(archive_path: str, out_dir: str, password: bytes = b"kf"):
    os.makedirs(out_dir, exist_ok=True)
    unpacked_files = []
    with open(archive_path, "rb") as f:
        hdr = f.read(16)
        magic, zero, dir_off = struct.unpack("<4sIQ", hdr)
        assert magic == b"GCAX", f"Invalid magic in {archive_path}"
        f.seek(dir_off)
        footer = bytearray(f.read())

        flags, fsize = struct.unpack_from("<IQ", footer, 4)
        if flags & 2:
            hcipher = GflGCACryptograph(password + b"Header")
            footer[0x10:] = hcipher.decrypt(bytes(footer[0x10:]))

        chk, crc, count, unk = struct.unpack_from("<IIII", footer, 0x10)
        assert chk == 0, f"Header check failed: {chk}"
        entries_end = 0x20 + count * 0x20
        name_pos = entries_end
        cur_data_off = 0x10

        for i in range(count):
            e_off = 0x20 + i * 0x20
            e_crc, e_flags, e_time, e_usize, e_csize = struct.unpack_from("<IIQQQ", footer, e_off)
            nlen = struct.unpack_from("<H", footer, name_pos)[0]
            name_bytes = bytes(footer[name_pos + 2 : name_pos + 2 + nlen])
            name = name_bytes.decode("cp932", errors="replace")
            name_pos += 2 + nlen

            if e_flags == 0x10:
                os.makedirs(os.path.join(out_dir, name), exist_ok=True)
                continue

            f.seek(cur_data_off)
            raw = f.read(e_csize)
            cur_data_off += e_csize

            fcipher = GflGCACryptograph(password + name_bytes)
            dec = fcipher.decrypt(raw)
            calc_crc = zlib.crc32(dec) & 0xffffffff
            assert calc_crc == e_crc, f"CRC mismatch on {name}: {hex(calc_crc)} != {hex(e_crc)}"

            dest_path = os.path.join(out_dir, name)
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            with open(dest_path, "wb") as out_f:
                out_f.write(dec)
            unpacked_files.append(dest_path)
    return unpacked_files


# ==============================================================================
# 2. G2CD0461 (.g2) 字节码与字符串解析
# ==============================================================================

EMOTION_MAP = {
    "㍍": "[♥]",
    "㌍": "[？]",
    "㌦": "[！]",
    "㌫": "[汗]",
    "㌣": "[怒]",
}

EMOTION_ID_TO_NAME = {
    1: "calm",
    2: "happy",
    3: "angry",
    4: "disappointed",
    5: "surprised",
    6: "doubtful",
    7: "overjoyed",
    8: "sad",
    9: "dissatisfied",
    10: "impatient",
    11: "sick",
}

FC_EMO_RE = re.compile(r"gd[\\/]fc[\\/]f_(?:ch|cu|le|va|d[clh]?|li[clh]?|kr[clh]?|me[clh]?)(\d\d)\.spd", re.IGNORECASE)


def decode_g2_str(buf: bytes) -> str:
    """还原自 PrincessMaker4+.exe (0x47db50) 的 UTF-16LE 字符串解密算法"""
    n = len(buf)
    out = bytearray(n)
    for i in range(n):
        out[i] = (buf[i] - i - n) & 0xff
    s = out.decode("utf-16le", errors="replace")
    s = s.replace("\\n", "\n")
    for k, v in EMOTION_MAP.items():
        s = s.replace(k, v)
    return to_simplified_chinese(s)


def parse_g2_bytecode(path: str):
    with open(path, "rb") as f:
        data = f.read()
    assert data[:8] == b"G2CD0461", f"Not a G2CD0461 file: {path}"
    pos = 8
    while data[pos] != 0x1b:
        pos += 1
    pos += 1
    unk_hdr, count1 = struct.unpack_from("<II", data, pos)
    pos += 8

    # 偏移 -> 标签列表（同一个偏移可能有多个标签）
    offset_to_labels = defaultdict(list)
    label_to_offset = {}
    for _ in range(count1):
        val, slen = struct.unpack_from("<II", data, pos)
        pos += 8
        s = decode_g2_str(data[pos : pos + slen * 2])
        pos += slen * 2
        offset_to_labels[val].append(s)
        label_to_offset[s] = val

    count2 = struct.unpack_from("<I", data, pos)[0]
    pos += 4 + count2 * 4
    while data[pos] != 0x1b:
        pos += 1
    pos += 1
    bytecode = data[pos:]

    bpos = 0
    blen = len(bytecode)
    insns = []
    while bpos < blen:
        op_off = bpos
        op = bytecode[bpos]
        bpos += 1
        if op in (0x01, 0x02, 0x0f):
            slen = struct.unpack_from("<i", bytecode, bpos)[0]
            bpos += 4
            s = "" if slen < 0 else decode_g2_str(bytecode[bpos : bpos + slen * 2])
            if slen >= 0:
                bpos += slen * 2
            insns.append((op_off, op, s))
        elif op in (0x03, 0x13, 0x05, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x14, 0x20, 0x21, 0x22,
                    0x40, 0x41, 0x42, 0x44, 0x45, 0x46, 0x51, 0x52, 0x53):
            val = struct.unpack_from("<i", bytecode, bpos)[0]
            bpos += 4
            insns.append((op_off, op, val))
        elif op == 0x0c:
            v1, v2 = struct.unpack_from("<ii", bytecode, bpos)
            bpos += 8
            insns.append((op_off, op, (v1, v2)))
        else:
            insns.append((op_off, op, None))

    return insns, offset_to_labels, label_to_offset


# ==============================================================================
# 3. 场景标签分类与标题映射
# ==============================================================================

ENDING_TITLES = {
    "en01": "结局01：魔界公主 (魔界のプリンセス)",
    "en02": "结局02：魔王 (魔王)",
    "en03": "结局03：重返魔界 (魔界に帰る)",
    "en04": "结局04：与父亲结婚 / 父嫁 (パパと)",
    "en05": "结局05：公主 / 夏洛璐王子嫁 (プリンセス)",
    "en07": "结局07：与吉普结婚 / 吉普嫁 (キューブと)",
    "en08": "结局08：与利伊结婚 / 龙之青年嫁 (ドラゴンユースと)",
    "en09": "结局09：与巴洛亚结婚 / 魔界王子嫁 (ヴァロアと)",
    "en10": "结局10：人界勇者 (人間界の勇者)",
    "en12": "结局12：黑街老大 (暗黒街のボス)",
    "en13": "结局13：士兵 (兵士)",
    "en14": "结局14：王宫魔术师 (王宮魔術師)",
    "en15": "结局15：魔道士 (魔道士)",
    "en16": "结局16：占卜师 (占い師)",
    "en17": "结局17：女王 (女王)",
    "en18": "结局18：伯爵夫人 (伯爵夫人)",
    "en19": "结局19：下级贵族妇人 (下級貴族婦人)",
    "en20": "结局20：夜之女 (夜の女)",
    "en21": "结局21：大臣 (大臣)",
    "en22": "结局22：司法官 (司法官)",
    "en23": "结局23：官僚 (官僚)",
    "en24": "结局24：欺诈师 (詐欺師)",
    "en25": "结局25：国王侧室 (王の側室)",
    "en26": "结局26：嫁给富豪 (富豪と結婚)",
    "en27": "结局27：歌姬 (歌姫)",
    "en28": "结局28：女仆酒馆 (メイド酒場)",
    "en29": "结局29：修女 (シスター)",
    "en30": "结局30：主教 (司教)",
    "en31": "结局31：艺术家 (芸術家)",
    "en32": "结局32：普通结婚 (普通の結婚)",
    "en33": "结局33：自由职业 / 打工族 (フリーター)",
    "en34": "结局34：将军 (将軍)",
    "en35": "结局35：半兽人新娘 (オーク嫁)",
    "en36": "结局36：克莉丝提娜友情结局 (クリスチーナ)",
    "en37": "结局37：玛丽友情结局 (マリー)",
    "en38": "结局38：卡莲友情结局 (カレン)",
    "en39": "结局39：真·人界勇者 (真人間界の勇者)",
    "en42": "结局42：莉洁友情结局 (リーゼ)",
    "af_0": "后日谈0：人类的胜利 (人間の勝利)",
    "af_1": "后日谈1：魔族的胜利 (魔族の勝利)",
    "af_2": "后日谈2：与魔族共存 (魔族と共存)",
    "af_3": "后日谈3：魔族消失 (魔族消える)",
    "af_4": "后日谈4：第二次大战 (第二次大戦)",
    "af_5": "后日谈5：一家团圆 (一家団欒)",
}

STR_VAR_MAP = {
    0: "【存档标题】",
    1: "【存档备注】",
    2: "{daughter_name}",
    3: "{secondname}",
    4: "【对手】",
    9: "【行程名称】",
    10: "【行程信息1】",
    11: "【行程信息2】",
    12: "【行程信息3】",
    13: "【行程信息4】",
    15: "【优胜者】",
    16: "【亚军】",
    17: "【季军】",
}

OMAKE_FACE_CHAR = {
    0: "{daughter_name}",
    1: "莉洁",
    2: "克莉丝提娜",
    3: "玛丽",
}


def extract_scenes_from_g2(insns, offset_to_labels, is_omake=False):
    """
    遍历字节码指令流，按标签切分场景并还原：
    - 说话人 (Speaker)
    - 表情状态 (Emotion)
    - 语音编号 (Voice)
    - 完整对话段落 (Dialogue)
    - 玩家分支选项及跳转目标 (Choices)
    """
    scenes = []
    cur_scene = {
        "labels": ["START_INIT"],
        "offset": 0,
        "entries": []
    }
    scenes.append(cur_scene)

    speaker = None
    emotion = "calm"
    voice = None
    text_buf = []
    last_sprintf = ""
    full_text_mode = False

    # Omake 模式下的表情立绘角色追踪
    cg_char_var = 850 if is_omake else 829
    cg_face_var = 851 if is_omake else 830
    func_face_off = 1621 if is_omake else 2514
    clear_img_offs = {5170, 5291} if is_omake else {8809, 8982}
    text_full_off = 1089
    text_full_end_off = 1320
    cur_cg_char = 0

    def flush_text():
        nonlocal text_buf, voice
        if text_buf:
            raw_text = "".join(text_buf)
            # 清理首尾多余换行但保留段落内换行
            clean_text = raw_text.strip("\r\n")
            if clean_text:
                sp = speaker
                if full_text_mode and not sp:
                    sp = "旁白/独白"
                if is_omake and voice:
                    sp = "{daughter_name}"
                cur_scene["entries"].append({
                    "type": "dialogue",
                    "speaker": sp if sp else "旁白/父亲",
                    "emotion": emotion,
                    "voice": voice,
                    "text": clean_text,
                })
            text_buf = []
            voice = None

    n = len(insns)
    for i, (off, op, arg) in enumerate(insns):
        # 遇到新标签时，先刷出未完结的文本，再开启或合并场景块
        if off in offset_to_labels:
            flush_text()
            lbls = offset_to_labels[off]
            if (
                not cur_scene["entries"]
                and cur_scene["labels"] != ["START_INIT"]
                and any(nl.startswith(pl + "_") for pl in cur_scene["labels"] for nl in lbls)
            ):
                for l in lbls:
                    if l not in cur_scene["labels"]:
                        cur_scene["labels"].append(l)
            else:
                cur_scene = {
                    "labels": list(lbls),
                    "offset": off,
                    "entries": []
                }
                scenes.append(cur_scene)
            # 顶层事件切换时重置全屏文本状态与默认表情
            if any(not ("_" in l and l.split("_")[-1].isdigit()) for l in lbls):
                full_text_mode = False
                emotion = "calm"

        # 追踪 $cgChar 与 $cgFace 赋值
        if op == 0x40 and arg == cg_char_var:
            if i + 1 < n and insns[i + 1][1] == 0x03:
                cur_cg_char = insns[i + 1][2]
        elif op == 0x40 and arg == cg_face_var:
            if i + 1 < n and insns[i + 1][1] == 0x03:
                emo_val = insns[i + 1][2]
                if emo_val in EMOTION_ID_TO_NAME:
                    emotion = EMOTION_ID_TO_NAME[emo_val]

        # 追踪直接加载的头像文件表情 (如 gd\fc\F_CH02.spd, gd\fc\F_CU06.spd)
        if op == 0x02 and isinstance(arg, str):
            m = FC_EMO_RE.search(arg)
            if m:
                emo_val = int(m.group(1))
                if emo_val in EMOTION_ID_TO_NAME:
                    emotion = EMOTION_ID_TO_NAME[emo_val]

        # 函数调用 op=0x0a
        if op == 0x0a:
            if arg == text_full_off:
                flush_text()
                full_text_mode = True
                speaker = "旁白/独白"
            elif arg == text_full_end_off:
                flush_text()
                full_text_mode = False
                speaker = None
            elif arg in clear_img_offs:
                flush_text()
                if is_omake:
                    speaker = "旁白/爸爸"
            elif is_omake and arg == func_face_off:
                flush_text()
                speaker = OMAKE_FACE_CHAR.get(cur_cg_char, "{daughter_name}")

        # 文本指令 op=0x01
        elif op == 0x01:
            text_buf.append(arg)

        # 系统调用 op=0x05
        elif op == 0x05:
            # 1) 设置/清除说话人姓名框 (syscall 8448)
            if arg == 8448:
                flush_text()
                sp = None
                for j in range(1, min(5, i + 1)):
                    pop, parg = insns[i - j][1], insns[i - j][2]
                    if pop == 0x02:
                        sp = parg
                        break
                    elif pop == 0x42:
                        sp = STR_VAR_MAP.get(parg, f"$str_{parg}")
                        break
                    elif pop in (0x05, 0x06, 0x20):
                        break
                speaker = sp

            # 2) 播放语音 (syscall 5664)
            elif arg == 5664:
                for j in range(1, min(4, i + 1)):
                    pop, parg = insns[i - j][1], insns[i - j][2]
                    if pop == 0x02 and parg:
                        vname = os.path.basename(parg.replace("\\", "/"))
                        if vname.lower().endswith(".ogg"):
                            vname = vname[:-4]
                        voice = vname
                        break

            # 3) 行内插入字符串变量/文本 (syscall 4106)
            elif arg == 4106:
                if i > 0:
                    pop, parg = insns[i - 1][1], insns[i - 1][2]
                    if pop == 0x42:
                        if parg == 18:
                            text_buf.append(last_sprintf or "【数值】")
                        elif parg == 4 and speaker == "韦娜":
                            text_buf.append("{daughter_name}")
                        else:
                            text_buf.append(STR_VAR_MAP.get(parg, f"$str_{parg}"))
                    elif pop == 0x02:
                        text_buf.append(parg)
                    elif pop == 0xf0:
                        text_buf.append("【文本】")

            # 4) 格式化字符串 sprintf (syscall 6151)
            elif arg == 6151:
                for j in range(1, min(10, i + 1)):
                    pop, parg = insns[i - j][1], insns[i - j][2]
                    if pop == 0x02:
                        last_sprintf = parg
                        break

            # 5) 对话框点击等待/翻页 (syscall 4357, 4356, 4098)
            elif arg in (4357, 4356, 4098):
                flush_text()

            # 6) 清除消息窗口 (syscall 4160)
            elif arg == 4160:
                flush_text()

            # 7) Omake 模式下关闭立绘槽 82 (syscall 5378) -> 切换到爸爸/旁白
            elif is_omake and arg == 5378:
                prev_args = [insns[i - j][2] for j in range(1, min(5, i + 1)) if insns[i - j][1] == 0x03]
                if 82 in prev_args:
                    flush_text()
                    speaker = "旁白/爸爸"

            # 8) 分支选项 (syscall 4495, 4496, 4487)
            elif arg in (4495, 4496, 4487):
                flush_text()
                choice_text = None
                target_lbl = None
                if i >= 1 and insns[i - 1][1] == 0x02:
                    choice_text = insns[i - 1][2]
                    if i >= 2 and insns[i - 2][1] == 0x13:
                        tgt_off = insns[i - 2][2]
                        lbls = offset_to_labels.get(tgt_off)
                        target_lbl = lbls[0] if lbls else f"@{tgt_off}"
                if choice_text:
                    cur_scene["entries"].append({
                        "type": "choice",
                        "text": choice_text,
                        "target": target_lbl,
                    })

    flush_text()
    # 过滤掉没有任何对话或选项的纯逻辑标签块
    return [s for s in scenes if s["entries"]]


# ==============================================================================
# 4. 分类导出 Markdown / TXT / JSON
# ==============================================================================

CATEGORY_DEFS = [
    ("01_片头与系统初始剧情", "片头剧情、初始领养女儿及系统公共对话", lambda l: l.startswith(("START", "NormalStart", "begineStart", "room_debug", "Save", "NextDay", "Platform", "menu", "hc_"))),
    ("02_主线与支线剧情事件_ev", "主线剧情事件与角色支线事件 (ev001 - ev325)", lambda l: l.startswith("ev")),
    ("03_全结局与后日谈剧情_en_af", "全38种结局与6种魔界大战后日谈完整剧情 (en01 - en42, af_0 - af_5)", lambda l: l.startswith(("en", "af_"))),
    ("04_收获祭与庆典大赛剧情_fe_ha", "每年10月收获祭、武斗大会、舞蹈大赛、艺术祭剧情 (fe00 - fe04, ha)", lambda l: l.startswith(("fe", "ha"))),
    ("05_街道外出随机事件_tw", "街道各场所外出随机事件与偶遇对话 (tw01 - tw10)", lambda l: l.startswith("tw")),
    ("06_角色场所互动事件_at_ac", "与吉普、利伊、巴洛亚、夏洛璐、克莉丝汀娜、莉洁、玛莉等角色场所互动 (at / ac)", lambda l: l.startswith(("at", "ac"))),
    ("07_王城拜访对话_ca", "王城拜访官员、大臣、国王、王妃、公主/王子对话 (ca00 - ca09)", lambda l: l.startswith("ca")),
    ("08_房间日常_生日_节日对话_tk", "房间内与女儿交谈、零用钱、说教、生病看护、生日送礼、新年对话 (tk / room / e_birth / e_nfd / e_holi / re)", lambda l: l.startswith(("tk", "room", "e_birth", "e_nfd", "e_holi", "re"))),
    ("09_课程学习事件与对话_tr", "礼仪、舞蹈、武术、魔法、艺术、理论等课程上课与升级对话 (tr00 - tr09)", lambda l: l.startswith("tr")),
    ("10_打工事件与对话_al", "家政、保姆、旅馆、农场、教堂、家庭教师、餐厅、伐木、美容院、泥水匠、猎人、墓园、赌场、酒馆、女仆酒店等打工事件 (al00 - al14)", lambda l: l.startswith("al")),
    ("11_外出渡假事件与对话_va", "四季山林与海边渡假对话及CG事件 (va00 - va32)", lambda l: l.startswith("va")),
    ("12_商店购物与洋裁店对话_sp", "武器防具店、洋裁店、杂货店、黑市神秘商人对话 (sp / item)", lambda l: l.startswith(("sp", "item"))),
    ("13_教会医院与行程系统对话_m_adv", "教会捐款、医院看病、月末行程安排与建言对话 (m00 - m11 / adv / sch)", lambda l: l.startswith(("m0", "m1", "adv", "sch"))),
]


def get_scene_category(labels):
    for lbl in labels:
        for cat_id, _, pred in CATEGORY_DEFS:
            if pred(lbl):
                return cat_id
    return "01_片头与系统初始剧情"


def format_scene_md(scene) -> str:
    lines = []
    lbl_str = " / ".join(scene["labels"])
    title_extra = ""
    for l in scene["labels"]:
        if l in ENDING_TITLES:
            title_extra = f" — {ENDING_TITLES[l]}"
            break
    lines.append(f"### [{lbl_str}]{title_extra} (`@0x{scene['offset']:06x}`)")
    lines.append("")
    for entry in scene["entries"]:
        if entry["type"] == "dialogue":
            sp = entry["speaker"]
            v_str = f" `[{entry['voice']}]`" if entry.get("voice") else ""
            txt = entry["text"].replace("\n", "  \n  ")
            lines.append(f"- **{sp}**{v_str}：  \n  {txt}")
        elif entry["type"] == "choice":
            tgt = f" ➔ 跳转至 `[{entry['target']}]`" if entry.get("target") else ""
            lines.append(f"- 🔹 **【分支选项】** 「{entry['text']}」{tgt}")
    lines.append("")
    return "\n".join(lines)


def format_scene_txt(scene) -> str:
    lines = []
    lbl_str = " / ".join(scene["labels"])
    title_extra = ""
    for l in scene["labels"]:
        if l in ENDING_TITLES:
            title_extra = f" ({ENDING_TITLES[l]})"
            break
    lines.append(f"================================================================================")
    lines.append(f"【场景标签】{lbl_str}{title_extra} (偏移: 0x{scene['offset']:06x})")
    lines.append(f"--------------------------------------------------------------------------------")
    for entry in scene["entries"]:
        if entry["type"] == "dialogue":
            sp = entry["speaker"]
            v_str = f" [{entry['voice']}]" if entry.get("voice") else ""
            txt = entry["text"].replace("\n", "\n    ")
            lines.append(f"【{sp}】{v_str}")
            lines.append(f"    {txt}")
        elif entry["type"] == "choice":
            tgt = f"  --> 跳转至 [{entry['target']}]" if entry.get("target") else ""
            lines.append(f"  ◆ [选项] {entry['text']}{tgt}")
    lines.append("")
    return "\n".join(lines)


def main():
    out_root = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.dirname(out_root)
    raw_main_dir = os.path.join(out_root, "raw_unpacked", "PrincessMaker4+")
    raw_omake_dir = os.path.join(out_root, "raw_unpacked", "PM4Omake")
    os.makedirs(out_root, exist_ok=True)

    print("[1/4] 正在检查/解密并解包 GCAX 剧本封包...")
    if not os.path.exists(os.path.join(raw_main_dir, "room.g2")):
        unpack_gcax_archive(os.path.join(root_dir, "PrincessMaker4+", "script"), raw_main_dir, b"kf")
    if not os.path.exists(os.path.join(raw_omake_dir, "omake.g2")):
        unpack_gcax_archive(os.path.join(root_dir, "PM4Omake", "script"), raw_omake_dir, b"kf")

    print("[2/4] 正在反编译主游戏剧本 room.g2 与特典小剧场剧本 omake.g2...")
    main_insns, main_off2lbl, _ = parse_g2_bytecode(os.path.join(raw_main_dir, "room.g2"))
    main_scenes = extract_scenes_from_g2(main_insns, main_off2lbl, is_omake=False)

    omk_insns, omk_off2lbl, _ = parse_g2_bytecode(os.path.join(raw_omake_dir, "omake.g2"))
    omk_scenes = extract_scenes_from_g2(omk_insns, omk_off2lbl, is_omake=True)

    print(f"  - 主游戏 (room.g2): 提取出 {len(main_scenes)} 个有效剧情段落")
    print(f"  - 特典小剧场 (omake.g2): 提取出 {len(omk_scenes)} 个有效剧情段落")

    print("[3/4] 正在按剧情类别生成简体中文 Markdown、TXT 与 JSON 文件...")
    cat_scenes = defaultdict(list)
    for sc in main_scenes:
        cat_id = get_scene_category(sc["labels"])
        cat_scenes[cat_id].append(sc)

    summary_stats = []
    master_txt_parts = [
        "================================================================================",
        "《美少女梦工厂4 完璧版》(Princess Maker 4 Perfect Edition) 全剧情对话完整提取合集（简体中文版）",
        "包含：主线/支线事件、全38结局+6后日谈、收获祭、街道外出、角色互动、日常对话、课程打工渡假、特典小剧场",
        "说明：女儿自定义名已统一替换为 {daughter_name}，自定义姓氏已替换为 {secondname}",
        "================================================================================\n"
    ]

    for cat_id, cat_desc, _ in CATEGORY_DEFS:
        scs = cat_scenes.get(cat_id, [])
        dlg_cnt = sum(sum(1 for e in s["entries"] if e["type"] == "dialogue") for s in scs)
        chk_cnt = sum(sum(1 for e in s["entries"] if e["type"] == "choice") for s in scs)
        md_filename = f"{cat_id}.md"
        md_path = os.path.join(out_root, md_filename)
        with open(md_path, "w", encoding="utf-8") as f:
            f.write(f"# {cat_id.replace('_', ' ')}\n\n")
            f.write(f"> **说明**：{cat_desc}  \n")
            f.write(f"> **统计**：共 **{len(scs)}** 个场景标签段落，**{dlg_cnt}** 句台词，**{chk_cnt}** 个分支选项。\n\n---\n\n")
            for sc in scs:
                f.write(format_scene_md(sc))
                f.write("\n")

        master_txt_parts.append(f"\n################################################################################")
        master_txt_parts.append(f"## 分类：{cat_id} ({cat_desc})")
        master_txt_parts.append(f"## 统计：{len(scs)} 个场景段落，{dlg_cnt} 句台词，{chk_cnt} 个分支选项")
        master_txt_parts.append(f"################################################################################\n")
        for sc in scs:
            master_txt_parts.append(format_scene_txt(sc))

        summary_stats.append((cat_id, cat_desc, md_filename, len(scs), dlg_cnt, chk_cnt))

    # 14: 特典小剧场 (PM4Omake)
    omk_id = "14_特典小剧场与互动对话_PM4Omake"
    omk_desc = "《美少女梦工厂4 完璧版》特典小剧场 (omk00 - omk19) 与触摸互动语音台词"
    omk_dlg_cnt = sum(sum(1 for e in s["entries"] if e["type"] == "dialogue") for s in omk_scenes)
    omk_chk_cnt = sum(sum(1 for e in s["entries"] if e["type"] == "choice") for s in omk_scenes)
    omk_md_filename = f"{omk_id}.md"
    with open(os.path.join(out_root, omk_md_filename), "w", encoding="utf-8") as f:
        f.write(f"# {omk_id.replace('_', ' ')}\n\n")
        f.write(f"> **说明**：{omk_desc}  \n")
        f.write(f"> **统计**：共 **{len(omk_scenes)}** 个场景标签段落，**{omk_dlg_cnt}** 句台词，**{omk_chk_cnt}** 个分支选项。\n\n---\n\n")
        for sc in omk_scenes:
            f.write(format_scene_md(sc))
            f.write("\n")

    master_txt_parts.append(f"\n################################################################################")
    master_txt_parts.append(f"## 分类：{omk_id} ({omk_desc})")
    master_txt_parts.append(f"## 统计：{len(omk_scenes)} 个场景段落，{omk_dlg_cnt} 句台词，{omk_chk_cnt} 个分支选项")
    master_txt_parts.append(f"################################################################################\n")
    for sc in omk_scenes:
        master_txt_parts.append(format_scene_txt(sc))

    summary_stats.append((omk_id, omk_desc, omk_md_filename, len(omk_scenes), omk_dlg_cnt, omk_chk_cnt))

    # 15: 道具名称与说明图鉴
    print("[4/4] 正在导出道具图鉴与全量汇总文件...")
    with open(os.path.join(raw_main_dir, "item_nam.txt"), "rb") as f:
        item_names = [to_simplified_chinese(x) for x in f.read().decode("utf-16le", errors="replace").lstrip("\ufeff").splitlines()]
    with open(os.path.join(raw_main_dir, "item_msg.txt"), "rb") as f:
        item_msgs = [to_simplified_chinese(x) for x in f.read().decode("utf-16le", errors="replace").lstrip("\ufeff").splitlines()]

    item_md_filename = "15_道具名称与说明图鉴.md"
    with open(os.path.join(out_root, item_md_filename), "w", encoding="utf-8") as f:
        f.write("# 15 道具名称与说明图鉴\n\n")
        f.write("| 编号 | 道具名称 | 道具说明 |\n| :--- | :--- | :--- |\n")
        for idx, (nam, msg) in enumerate(zip(item_names, item_msgs)):
            nam_c = nam.strip()
            msg_c = msg.strip().replace("\\n", " — ")
            if nam_c or msg_c:
                f.write(f"| {idx:02d} | **{nam_c}** | {msg_c} |\n")

    # 保存完整版 TXT 合集
    master_txt_path = os.path.join(out_root, "PM4_全剧情文本合集_完整版.txt")
    with open(master_txt_path, "w", encoding="utf-8") as f:
        f.write("\n".join(master_txt_parts))

    # 保存结构化 JSON
    json_path = os.path.join(out_root, "PM4_全剧情文本数据.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump({
            "main_game_scenes": main_scenes,
            "omake_scenes": omk_scenes,
            "items": [
                {"id": idx, "name": n.strip(), "description": m.strip().replace("\\n", "\n")}
                for idx, (n, m) in enumerate(zip(item_names, item_msgs))
                if n.strip() or m.strip()
            ]
        }, f, ensure_ascii=False, indent=2)

    # 生成 00_目录与说明_README.md
    total_scenes = sum(x[3] for x in summary_stats)
    total_dlgs = sum(x[4] for x in summary_stats)
    total_chks = sum(x[5] for x in summary_stats)
    readme_path = os.path.join(out_root, "00_目录与说明_README.md")
    with open(readme_path, "w", encoding="utf-8") as f:
        f.write("# 《美少女梦工厂4 完璧版》全文本与剧情对话提取目录（简体中文版）\n\n")
        f.write("## 1. 解密与逆向工程说明\n\n")
        f.write("- **封包格式 (`GCAX` / `GCA3`)**：主游戏 `PrincessMaker4+\\script` 与特典 `PM4Omake\\script` 均采用 `GflGCACryptograph` 自定义流密码加密（基于改造版 MT19937 伪随机数生成器，每 4 字节消耗 8 个随机数进行移位异或与加减运算）。\n")
        f.write("- **封包密钥**：逆向 `PrincessMaker4+.exe` (`0x404eca` / `0x50cc98`) 提取出硬编码密码为 `\"kf\"`（索引头密钥为 `\"kfHeader\"`，子文件密钥为 `\"kf\" + 文件名`）。所有解包文件均通过 100% CRC32 校验。\n")
        f.write("- **脚本字节码 (`G2CD0461` / `.g2`)**：剧本编译为自定义栈虚拟机字节码，内嵌字符串经 `(byte - index - byte_length) & 0xFF` 逐字节混淆后以 `UTF-16LE` 存储。\n")
        f.write("- **剧情结构还原**：通过反编译全量字节码指令流（`room.g2` 共 405,528 条指令、`omake.g2` 共 16,920 条指令），完整还原了 **说话人姓名 (`syscall 8448`)**、**表情状态 (`emotion`)**、**语音文件 (`syscall 5664`)**、**多段行内变量拼接台词 (`op=0x01` + `syscall 4106`)**、**表情符号 (`[♥]`, `[？]`, `[！]`, `[汗]`, `[怒]`)** 以及 **分支选项与跳转目标标签 (`syscall 4495/4487`)**。\n")
        f.write("- **简体中文与自定义女儿姓名**：所有提取文本已统一转换为简体中文，女儿默认名“派翠西亚”已替换为玩家自定义名字占位符 `{daughter_name}`，姓氏“海斯”已替换为 `{secondname}`。\n\n")
        f.write("## 2. 提取文件汇总表\n\n")
        f.write(f"- **总计场景段落**：**{total_scenes:,}** 个\n")
        f.write(f"- **总计剧情台词**：**{total_dlgs:,}** 句\n")
        f.write(f"- **总计分支选项**：**{total_chks:,}** 个\n\n")
        f.write("| 分类文件 | 内容说明 | 场景段落数 | 台词句数 | 分支选项数 |\n")
        f.write("| :--- | :--- | :---: | :---: | :---: |\n")
        for cat_id, cat_desc, md_fn, sc_c, dlg_c, chk_c in summary_stats:
            f.write(f"| [{md_fn}](./{md_fn}) | {cat_desc} | {sc_c} | {dlg_c} | {chk_c} |\n")
        f.write(f"| [{item_md_filename}](./{item_md_filename}) | 全部 89 种道具名称与效果说明 | - | 89 | - |\n")
        f.write(f"| [PM4_全剧情文本合集_完整版.txt](./PM4_全剧情文本合集_完整版.txt) | 单文件纯文本全集（适合全文搜索与阅读） | {total_scenes} | {total_dlgs} | {total_chks} |\n")
        f.write(f"| [PM4_全剧情文本数据.json](./PM4_全剧情文本数据.json) | 结构化 JSON 数据（含字节码偏移、标签、表情、语音文件名、跳转目标） | {total_scenes} | {total_dlgs} | {total_chks} |\n")

    print(f"\n全部提取完成！输出目录: {out_root}")
    print(f"总计: {total_scenes} 个场景段落, {total_dlgs} 句台词, {total_chks} 个选项。")


if __name__ == "__main__":
    main()
