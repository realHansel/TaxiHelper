script_name('Taxi Helper 2.5')
script_version('2.5')

require 'lib.moonloader'
local sampev = require 'samp.events'
local imgui = require 'imgui'
local inicfg = require 'inicfg'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local config_path = 'TaxiHelper.ini'

local function _fix_base(path)
    if not path then return '' end
    return (path:gsub('[\\/]moonloader[\\/]moonloader', '\\moonloader'))
end

local _cached_base = nil
local function script_base()
    if _cached_base then return _cached_base end
    local base
    local ok, s = pcall(thisScript)
    if ok and s and type(s.dir) == 'string' and s.dir ~= '' then
        base = s.dir
    else
        base = getWorkingDirectory() or ''
    end
    _cached_base = _fix_base(base)
    return _cached_base
end

local L = {
    window       = u8'Taxi Helper',
    title        = u8'TAXI HELPER',
    move_mode    = u8'[РЕЖИМ ПЕРЕМЕЩЕНИЯ]',
    save_pos     = u8'Сохранить положение',
    rides        = u8'Рейсов:',
    earned       = u8'Заработано:',
    best         = u8'Лучший рейс:',
    session_time = u8'Время сессии:',
    day_header   = u8'ЗАРАБОТОК ЗА ДЕНЬ',
    worked       = u8'Отработано:',
    dash         = u8'-',
    long_dash    = u8'—',
    notify_id    = u8'##TaxiRideNotification',
    ride_done    = u8'РЕЙС ЗАВЕРШЁН',
    plus         = u8'+ ',
    session_sum  = u8'Заработано за сессию:',
    day_sum      = u8'Заработано сегодня:',
    avg          = u8'Средний чек:',
    sec_windows  = u8'ОКНА',
    opt_stats    = u8'Окно статистики на экране',
    opt_notify   = u8'Всплывающие уведомления',
    btn_move     = u8'Переместить окно статистики',
    sec_session  = u8'ПУНКТЫ СТАТИСТИКИ: СЕССИЯ',
    sec_day      = u8'ПУНКТЫ СТАТИСТИКИ: ЗА ДЕНЬ',
    i_rides      = u8'Рейсов',
    i_earned     = u8'Заработано',
    i_avg        = u8'Средний чек',
    i_time       = u8'Время сессии',
    i_worked     = u8'Отработано',
    i_boxes      = u8'Получено ларцов',
    i_coins      = u8'Монеты таксиста',
    i_tips       = u8'Чаевые таксиста',
    sec_total    = u8'ВСЕГО ЗА ВСЕ ДНИ',
    total_fmt    = u8'Рейсов: %d     Дней: %d     Средний чек: $%s',
    col_date     = u8'Дата',
    col_rides    = u8'Рейсов',
    col_money    = u8'Заработано',
    col_avg      = u8'Средний чек',
    today        = u8'сегодня',
    no_data      = u8'Данных пока нет. Статистика появится после первого рейса.',
    sec_orders   = u8'ЛОВЛЯ ЗАКАЗОВ',
    order_dist   = u8'Макс. дистанция (м)',
    bot_only     = u8'Принимать заказы только от ботов',
    auto_catch   = u8'Автоматически ловить заказы',
    catch_mode   = u8'Режим ловли',
    sound_on     = u8'Звук при поимке заказа',
    sound_kind   = u8'Мелодия',
    sound_volume = u8'Громкость',
    sound_test   = u8'Проверить звук',
    snd_1        = u8'Такси-приложение',
    snd_2        = u8'Колокольчик',
    snd_3        = u8'Двойной сигнал',
    snd_4        = u8'Арпеджио',
    snd_5        = u8'Свой файл',
    snd_6        = u8'Яндекс-такси',
    mode_instant = u8'Моментальный',
    mode_nearest = u8'Ближайший заказ',
    sec_goal     = u8'ЦЕЛЬ ЗАРАБОТКА',
    goal_amount  = u8'Цель на день ($)',
    goal_off     = u8'0 - отключить отображение цели',
    sec_meter    = u8'ТАКСОМЕТР',
    meter_show   = u8'Показывать таксометр',
    meter_auto   = u8'Автокалибровка по оплате',
    meter_coeff  = u8'Коэффициент',
    meter_move   = u8'Переместить таксометр',
    meter_title  = u8'ТАКСОМЕТР',
    meter_base   = u8'База',
    meter_income = u8'Доход',
    meter_time   = u8'В пути',
    meter_need   = u8'Нужна калибровка — сделайте один рейс',
    meter_paid   = u8'Оплачено',
    meter_reset  = u8'Сбросить калибровку',
    sec_keys     = u8'БЫСТРОЕ МЕНЮ',
    menu_key     = u8'Открытие меню',
    key_bind     = u8'Клавиша',
    key_none     = u8'не назначена',
    key_press    = u8'Жмите клавишу...',
    key_off      = u8'Убрать',
    key_hint     = u8'Esc - отмена. Не срабатывает в чате и диалогах.',
    key_note     = u8'Меню также открывается командой /thelper',
}

local DOLLAR_COLOR     = imgui.ImVec4(0.35, 1.0, 0.35, 1.0)
local HEADER_DAY_COLOR = imgui.ImVec4(0.55, 0.85, 1.0, 1.0)
local TAXI_YELLOW      = imgui.ImVec4(0.26, 0.98, 0.26, 1.0)
local TAXI_WHITE       = imgui.ImVec4(1.0, 1.0, 1.0, 1.0)
local WINDOW_BG        = imgui.ImVec4(0.045, 0.055, 0.075, 0.70)
local WINDOW_BORDER    = imgui.ImVec4(0.26, 0.98, 0.26, 0.35)

local SEP_SESSION      = {255, 200, 60}
local SEP_DAY          = {100, 200, 255}

local SEP_PAD_TOP      = 6
local SEP_PAD_BOTTOM   = 6
local COL_X            = 190

local UNFINISHED_SAVE_INTERVAL = 30

local active       = false
local busy         = false
local catching     = false
local catchStart   = 0

local order_notify = {
    pickup_seen   = false,
    awaiting_dest = false,
    dest_shown    = false,
}

local orders        = {}
local order_is_bot  = {}
local order_seen_at = {}
local order_retry_at = {}
local lastPicked    = nil
local lastPickedDist = 0

local AUTO          = true
local NEAREST       = true
local CATCH_TIMEOUT = 3500
local ORDER_RETRY_DELAY = 100
local ORDER_STALE_MS = 120000
local ORDER_COLLECT_MS = 2
local order_collect_start = 0
local order_collect_until = 0

local DIALOG_CONFIRM = 15324
local DIALOG_START   = 26919

local menu_open      = imgui.ImBool(false)
local dragStartPos   = nil

local gta = true
goal_keyboard_editor = false
goal_keyboard_digits = ''
goal_keyboard_replace = false
goal_keyboard_save = false
goal_keyboard_cancel = false

-- === Горячая клавиша открытия меню ===
menu_key         = 0
menu_key_held    = false
menu_key_capture = false
menu_key_changed = false

local VK_SPECIAL = {
    [8] = 'Backspace', [9] = 'Tab', [13] = 'Enter', [16] = 'Shift', [17] = 'Ctrl',
    [18] = 'Alt', [19] = 'Pause', [20] = 'CapsLock', [27] = 'Esc', [32] = 'Space',
    [33] = 'PgUp', [34] = 'PgDn', [35] = 'End', [36] = 'Home', [37] = 'Left',
    [38] = 'Up', [39] = 'Right', [40] = 'Down', [45] = 'Insert', [46] = 'Delete',
    [91] = 'Win', [92] = 'Win', [93] = 'Menu', [106] = 'Num *', [107] = 'Num +',
    [109] = 'Num -', [110] = 'Num .', [111] = 'Num /', [186] = ';', [187] = '=',
    [188] = ',', [189] = '-', [190] = '.', [191] = '/', [192] = '`',
    [219] = '[', [220] = '\\', [221] = ']', [222] = "'",
}

local function key_vk_name(vk)
    vk = tonumber(vk) or 0
    if vk <= 0 then return '-' end
    if VK_SPECIAL[vk] then return VK_SPECIAL[vk] end
    if vk >= 48 and vk <= 57 then return string.char(vk) end
    if vk >= 65 and vk <= 90 then return string.char(vk) end
    if vk >= 96 and vk <= 105 then return 'Num ' .. tostring(vk - 96) end
    if vk >= 112 and vk <= 123 then return 'F' .. tostring(vk - 111) end
    return 'VK ' .. tostring(vk)
end

local function is_modifier_key(vk)
    return vk == 16 or vk == 17 or vk == 18 or vk == 91 or vk == 92 or vk == 93
end

local function chat_busy()
    if type(sampIsChatInputActive) == 'function' then
        local ok, res = pcall(sampIsChatInputActive)
        if ok and res == true then return true end
    end
    if type(sampIsDialogActive) == 'function' then
        local ok, res = pcall(sampIsDialogActive)
        if ok and res == true then return true end
    end
    return false
end

local function text_input_active()
    local ok, res = pcall(function() return imgui.GetIO().WantTextInput end)
    return ok and res == true
end

addEventHandler("onWindowMessage", function(msg, wparam)
    if msg == 6 then
        gta = wparam ~= 0
    end

    if menu_key_capture then
        if msg == 0x100 then
            if wparam == 0x1B then
                menu_key_capture = false
                consumeWindowMessage(true, true)
                return
            elseif is_modifier_key(wparam) then
                consumeWindowMessage(true, true)
                return
            else
                menu_key = wparam
                menu_key_held = true
                menu_key_capture = false
                menu_key_changed = true
                consumeWindowMessage(true, true)
                return
            end
        end
        return
    end

    if goal_keyboard_editor then
        if not menu_open.v then
            goal_keyboard_editor = false
        elseif msg == 0x102 then
            if wparam >= 48 and wparam <= 57 and #goal_keyboard_digits < 12 then
                local digit = string.char(wparam)
                if goal_keyboard_replace or goal_keyboard_digits == '0' then
                    goal_keyboard_digits = digit
                    goal_keyboard_replace = false
                else
                    goal_keyboard_digits = goal_keyboard_digits .. digit
                end
            end
            consumeWindowMessage(true, true)
            return
        elseif msg == 0x100 then
            if wparam == 0x08 then
                if goal_keyboard_replace then
                    goal_keyboard_digits = ''
                    goal_keyboard_replace = false
                else
                    goal_keyboard_digits = goal_keyboard_digits:sub(1, -2)
                end
                consumeWindowMessage(true, true)
                return
            elseif wparam == 0x0D then
                goal_keyboard_save = true
                consumeWindowMessage(true, true)
                return
            elseif wparam == 0x1B then
                goal_keyboard_cancel = true
                esc_swallowed = true
                consumeWindowMessage(true, true)
                return
            end
        end
    end

    if msg == 0x101 and menu_key > 0 and wparam == menu_key then
        menu_key_held = false
    end

    if msg == 0x100 and menu_key > 0 and wparam == menu_key and not menu_key_held
        and gta and not goal_keyboard_editor and not text_input_active()
        and not chat_busy() then
        menu_key_held = true
        menu_open.v = not menu_open.v
        if not menu_open.v then
            goal_keyboard_editor = false
            imgui.ShowCursor = false
        end
        consumeWindowMessage(true, false)
        return
    end

    if msg == 0x100 and wparam == 0x1B and menu_open.v then
        menu_open.v = false
        imgui.ShowCursor = false
        esc_swallowed = true
        consumeWindowMessage(true, false)
    elseif msg == 0x101 and wparam == 0x1B and esc_swallowed then
        esc_swallowed = false
        consumeWindowMessage(true, false)
    end
end)

local defaults = {
    window  = { x = 100, y = 100, show = true },
    meter   = { x = 100, y = 430, show = true },
    session = { rides = 0, money = 0, best_ride = 0, unfinished = 0 },
    day     = { date = '', rides = 0, money = 0, worked = 0, boxes = 0, coins = 0, tips = 0, tips_cash = 0 },
    ui      = { notify = 1,
                s_rides = 1, s_money = 1, s_avg = 1, s_time = 1,
                d_money = 1, d_worked = 1, d_rides = 1, d_boxes = 1, d_coins = 1, d_tips = 1, d_avg = 0,
                max_distance = 3500, bot_only = 0, auto_catch = 1, catch_mode = 2, goal_amount = 0,
                sound_on = 1, sound_kind = 6, sound_volume = 70 }
}

local cfg = inicfg.load(defaults, config_path)

local UI_DEFAULTS = {
    notify = 1,
    meter_show = 1, meter_auto = 1,
    s_rides = 1, s_money = 1, s_avg = 1, s_time = 1,
    d_money = 1, d_worked = 1, d_rides = 1, d_boxes = 1, d_coins = 1, d_tips = 1, d_avg = 0,
    max_distance = 3500, bot_only = 0, auto_catch = 1, catch_mode = 2, goal_amount = 0,
    sound_on = 1, sound_kind = 6, sound_volume = 70
}

if type(cfg.ui) ~= 'table' then cfg.ui = {} end
if type(cfg.meter) ~= 'table' then cfg.meter = {} end
if cfg.meter.x == nil then cfg.meter.x = 100 end
if cfg.meter.y == nil then cfg.meter.y = 430 end
if cfg.meter.show == nil then cfg.meter.show = true end
menu_key = math.max(0, math.floor(tonumber(cfg.ui.menu_key) or 114))
cfg.ui.menu_key = menu_key

local uib = {}
for key, def in pairs(UI_DEFAULTS) do
    local v = tonumber(cfg.ui[key])
    if v == nil then v = def end
    if key == 'max_distance' or key == 'goal_amount' or key == 'catch_mode' or key == 'sound_kind' or key == 'sound_volume' then
        uib[key] = imgui.ImInt(v)
    else
        uib[key] = imgui.ImBool(v == 1)
    end
end

TaxiHelperSound = { ring = {}, RATE = 22050 }

function TaxiHelperSound.dir()
    return getWorkingDirectory() .. '\\resource\\TaxiHelper'
end

function TaxiHelperSound.ensure_dir()
    local d = TaxiHelperSound.dir()
    if not doesDirectoryExist(d) then
        pcall(createDirectory, getWorkingDirectory() .. '\\resource')
        pcall(createDirectory, d)
    end
    return doesDirectoryExist(d)
end

function TaxiHelperSound.file_size(path)
    local f = io.open(path, 'rb')
    if not f then return 0 end
    local size = f:seek('end') or 0
    f:close()
    return size
end

function TaxiHelperSound.synth(kind)
    local bit = require 'bit'
    local rate = TaxiHelperSound.RATE
    local lengths = { 2.4, 2.2, 1.4, 2.2 }
    local n = math.floor(lengths[kind] * rate)
    local buf = {}
    for i = 1, n do buf[i] = 0 end

    local function add(freq, start, dur, amp, decay, partials)
        local s0 = math.floor(start * rate)
        local cnt = math.floor(dur * rate)
        for i = 0, cnt - 1 do
            local idx = s0 + i + 1
            if idx > n then break end
            local t = i / rate
            local env = math.exp(-t / decay) * math.min(1, t / 0.004) * math.max(0, math.min(1, (dur - t) / 0.03))
            local v = 0
            for _, p in ipairs(partials) do
                v = v + p[2] * math.sin(2 * math.pi * freq * p[1] * t)
            end
            buf[idx] = buf[idx] + v * env * amp
        end
    end

    local warm = { { 1, 1 }, { 2, 0.28 }, { 3, 0.09 } }
    local bell = { { 1, 1 }, { 2.76, 0.5 }, { 5.4, 0.22 }, { 8.93, 0.1 } }
    local soft = { { 1, 1 }, { 2, 0.12 } }

    if kind == 1 then
        add(659.25, 0.00, 1.1, 0.55, 0.30, warm)
        add(880.00, 0.24, 1.6, 0.60, 0.42, warm)
    elseif kind == 2 then
        add(1318.5, 0.00, 1.6, 0.60, 0.50, bell)
        add(1318.5, 0.42, 1.4, 0.32, 0.45, bell)
    elseif kind == 3 then
        add(987.77, 0.00, 0.14, 0.55, 0.30, soft)
        add(987.77, 0.22, 0.14, 0.55, 0.30, soft)
    else
        add(523.25, 0.00, 0.9, 0.45, 0.28, warm)
        add(659.25, 0.12, 0.9, 0.45, 0.28, warm)
        add(783.99, 0.24, 0.9, 0.45, 0.28, warm)
        add(1046.5, 0.36, 1.3, 0.50, 0.38, warm)
    end

    local d1, d2 = math.floor(0.17 * rate), math.floor(0.34 * rate)
    local out = {}
    local peak = 0
    for i = 1, n do
        local v = buf[i]
        if i > d1 then v = v + 0.30 * buf[i - d1] end
        if i > d2 then v = v + 0.15 * buf[i - d2] end
        out[i] = v
        if math.abs(v) > peak then peak = math.abs(v) end
    end
    local scale = peak > 0 and 0.82 / peak or 1

    local function u16(v) return string.char(bit.band(v, 255), bit.band(bit.rshift(v, 8), 255)) end
    local function u32(v) return u16(bit.band(v, 65535)) .. u16(bit.band(bit.rshift(v, 16), 65535)) end

    local data = {}
    for i = 1, n do
        local v = math.floor(out[i] * scale * 32767 + 0.5)
        if v < 0 then v = v + 65536 end
        data[i] = u16(v)
    end
    local pcm = table.concat(data)
    return 'RIFF' .. u32(36 + #pcm) .. 'WAVEfmt ' .. u32(16) .. u16(1) .. u16(1)
        .. u32(rate) .. u32(rate * 2) .. u16(2) .. u16(16) .. 'data' .. u32(#pcm) .. pcm
end

TaxiHelperSound.YANDEX_URL = 'https://zvukoviku.ru/sounds/1587312926_dadsdasasdas.mp3'
TaxiHelperSound.YANDEX_DL  = false
TaxiHelperSound._ffi       = nil
TaxiHelperSound._winmm     = nil

function TaxiHelperSound.valid_media(path)
    if not path or not doesFileExist(path) then return false end
    if TaxiHelperSound.file_size(path) < 20000 then return false end
    local f = io.open(path, 'rb')
    if not f then return false end
    local h = f:read(4) or ''
    f:close()
    return h:sub(1, 3) == 'ID3' or h:sub(1, 3) == 'RIFF' or h:sub(1, 4) == 'OggS' or h:byte(1) == 0xFF
end

-- Автозагрузка звука "Яндекс-такси" (аналогично fa_ensure_font)
function TaxiHelperSound.ensure_yandex()
    if TaxiHelperSound.YANDEX_DL then return end
    if not TaxiHelperSound.ensure_dir() then return end
    local p = TaxiHelperSound.dir() .. '\\yandex.mp3'
    if TaxiHelperSound.valid_media(p) then return end
    if type(downloadUrlToFile) ~= 'function' then return end
    local tmp = p .. '.download'
    os.remove(tmp)
    TaxiHelperSound.YANDEX_DL = true
    pcall(function()
        downloadUrlToFile(TaxiHelperSound.YANDEX_URL, tmp, function(id, status)
            local ds = require('moonloader').download_status
            if status == ds.STATUS_ENDDOWNLOADDATA then
                TaxiHelperSound.YANDEX_DL = false
                if TaxiHelperSound.valid_media(tmp) then
                    os.remove(p)
                    if os.rename(tmp, p) then
                        AHKMessage('Звук «Яндекс-такси» загружен.')
                    else
                        os.remove(tmp)
                    end
                else
                    os.remove(tmp)
                    AHKMessage('Звук «Яндекс-такси»: скачан неверный файл. Положите yandex.mp3 в moonloader\\resource\\TaxiHelper вручную.', 0xFFAA00)
                end
            elseif status == ds.STATUS_ERROR then
                TaxiHelperSound.YANDEX_DL = false
                os.remove(tmp)
                AHKMessage('Не удалось скачать звук «Яндекс-такси». Скачайте вручную: ' .. TaxiHelperSound.YANDEX_URL, 0xFFAA00)
            end
        end)
    end)
end

-- === winmm-проигрыватель: работает и когда игра свёрнута ===
function TaxiHelperSound.winmm()
    if TaxiHelperSound._winmm then return TaxiHelperSound._winmm end
    local ok, ffi = pcall(require, 'ffi')
    if not ok then return nil end
    local okc = pcall(ffi.cdef, [[
        uint32_t mciSendStringW(const uint16_t* command, uint16_t* ret, int32_t len, void* hwnd);
        int32_t  PlaySoundW(const uint16_t* name, void* hmod, uint32_t flags);
    ]])
    if not okc then return nil end
    local okl, winmm = pcall(ffi.load, 'winmm')
    if not okl then return nil end
    TaxiHelperSound._ffi   = ffi
    TaxiHelperSound._winmm = winmm
    return winmm
end

function TaxiHelperSound.to_wide(s)
    local ffi = TaxiHelperSound._ffi
    local buf = ffi.new('uint16_t[?]', #s + 1)
    for i = 1, #s do buf[i - 1] = s:byte(i) end
    return buf
end

function TaxiHelperSound.play_winmm(path, volume)
    local winmm = TaxiHelperSound.winmm()
    if not winmm then return false, 'winmm' end
    local w = TaxiHelperSound.to_wide
    winmm.mciSendStringW(w('close TaxiHelperSnd'), nil, 0, nil)
    local ext = (path:match('%.(%w+)$') or ''):lower()
    local order = (ext == 'wav') and { 'waveaudio', 'mpegvideo' } or { 'mpegvideo', 'waveaudio' }
    local opened = false
    for _, t in ipairs(order) do
        local cmd = ('open "%s" type %s alias TaxiHelperSnd'):format(path, t)
        if winmm.mciSendStringW(w(cmd), nil, 0, nil) == 0 then opened = true break end
    end
    if opened then
        local vol = math.max(0, math.min(100, tonumber(volume) or 70)) * 10 -- 0..1000
        winmm.mciSendStringW(w(('setaudio TaxiHelperSnd volume to %d'):format(vol)), nil, 0, nil)
        winmm.mciSendStringW(w('play TaxiHelperSnd from 0'), nil, 0, nil)
        return true
    end
    if ext == 'wav' then -- последний fallback: PlaySoundW
        if winmm.PlaySoundW(w(path), nil, 0x1 + 0x20000 + 0x10) ~= 0 then return true end -- SND_ASYNC|SND_FILENAME|SND_NOSTOP
    end
    return false, 'open'
end

function TaxiHelperSound.file_for(kind)
    if not TaxiHelperSound.ensure_dir() then return nil, 'dir' end
    if kind == 5 then
        for _, ext in ipairs({ 'mp3', 'wav', 'ogg' }) do
            local p = TaxiHelperSound.dir() .. '\\custom.' .. ext
            if doesFileExist(p) then return p end
        end
        return nil, 'custom'
    end
    if kind == 6 then
        local p = TaxiHelperSound.dir() .. '\\yandex.mp3'
        if TaxiHelperSound.valid_media(p) then return p end
        TaxiHelperSound.ensure_yandex()
        return nil, 'yandex'
    end
    local p = TaxiHelperSound.dir() .. '\\order_' .. kind .. '.wav'
    if TaxiHelperSound.file_size(p) < 4000 then
        local ok, data = pcall(TaxiHelperSound.synth, kind)
        if not ok or not data then return nil, 'synth' end
        local f = io.open(p, 'wb')
        if not f then return nil, 'write' end
        f:write(data)
        f:close()
    end
    return p
end

function TaxiHelperSound.play(kind)
    local path, why = TaxiHelperSound.file_for(kind)
    if not path then return false, why end
    local volume = tonumber(uib.sound_volume.v) or 70
    local ok = TaxiHelperSound.play_winmm(path, volume)
    if ok then return true end
    local ok2, stream = pcall(loadAudioStream, (path:gsub('\\', '/')))
    if not ok2 or not stream then return false, 'stream' end
    pcall(setAudioStreamVolume, stream, math.max(0, math.min(100, volume)))
    pcall(setAudioStreamState, stream, 1)
    local ring = TaxiHelperSound.ring
    ring[#ring + 1] = stream
    if #ring > 3 then table.remove(ring, 1) end
    return true
end

function TaxiHelperSound.play_selected()
    local ok, why = TaxiHelperSound.play(tonumber(uib.sound_kind.v) or 1)
    if not ok then
        if why == 'custom' then
            AHKMessage('Звук: положи файл custom.mp3 (или .wav / .ogg) в moonloader\\resource\\TaxiHelper', 0xFFAA00)
        elseif why == 'yandex' then
            AHKMessage('Звук: «Яндекс-такси» ещё загружается или не скачался. Проверь moonloader\\resource\\TaxiHelper\\yandex.mp3', 0xFFAA00)
        else
            AHKMessage('Звук: не удалось подготовить или воспроизвести файл (' .. tostring(why) .. ')', 0xFF5555)
        end
    end
    return ok
end


local waiting_payment       = false
local payment_deadline      = 0
local pending_deliveries    = {}
local PAYMENT_TIMEOUT      = 15
local MAX_PENDING_PAYMENTS = 5
local last_payment_text    = nil
local last_payment_ms      = 0
local session_start         = 0
local work_segment_start    = 0
local session_elapsed       = 0
local last_unfinished_save  = 0
local rewards_dirty         = false

local pending_boxes = 0

local show      = imgui.ImBool(cfg.window.show == true or cfg.window.show == 'true')
local edit_mode = false

local notification_show = imgui.ImBool(false)

local notification = {
    active = false,
    started = 0,
    ride_money = 0,
    session_money = 0,
    day_money = 0,
    meter_base = 0,
    meter_k = 0,
    meter_income = 0,
}

local NOTIFY_DURATION = 7000
local NOTIFY_FADE_IN = 1100
local NOTIFY_FADE_OUT = 1400

local function game_ms()
    if type(getGameTimer) == 'function' then
        return getGameTimer()
    end
    return math.floor(os.clock() * 1000)
end

local event_log = {}
local EVENT_LIMIT = 120
local event_rev = 0
local function event_file()
    return script_base() .. '\\config\\TaxiHelper_events.json'
end
local function event_load()
    local f = io.open(event_file(), 'rb')
    if not f then return end
    local data = f:read('*a'); f:close()
    local ok, parsed = pcall(decodeJson, data or '')
    if ok and type(parsed) == 'table' then
        event_log = {}
        for _, v in ipairs(parsed) do
            if type(v) == 'table' and type(v.text) == 'string' and type(v.time) == 'string' then
                event_log[#event_log+1] = {text=v.text, time=v.time}
                if #event_log >= EVENT_LIMIT then break end
            end
        end
    end
end
local function event_add(message)
    table.insert(event_log, 1, {time=os.date('%Y-%m-%d %H:%M:%S'), text=message})
    while #event_log > EVENT_LIMIT do table.remove(event_log) end
    event_rev = event_rev + 1
    local ok, data = pcall(encodeJson, event_log)
    if not ok or type(data) ~= 'string' then return end
    local path = event_file()
    local tmp = path .. '.tmp'
    local f = io.open(tmp, 'wb')
    if not f then return end
    local written = f:write(data)
    local closed = f:close()
    if written and closed then
        os.remove(path)
        if not os.rename(tmp, path) then os.remove(tmp) end
    else os.remove(tmp) end
end

local function chat_distance(m)
    m = math.max(0, tonumber(m) or 0)
    if m >= 1000 then
        return string.format('%.1f км', m / 1000)
    end
    return string.format('%d м', math.floor(m))
end

local function get_location(x, y)
    x, y = tonumber(x) or 0, tonumber(y) or 0
    if x >= 869 and x <= 2997 and y >= 596 and y <= 2993 then return 'Лас-Вентурас' end
    if x >= 44 and x <= 2997 and y >= -2892 and y <= -768 then return 'Лос-Сантос' end
    if x >= -2997 and x <= -1213 and y >= -1115 and y <= 1659 then return 'Сан-Фиерро' end
    return 'Сельская местность'
end

local function show_ride_notification(money, force)
    if not force and not uib.notify.v then return end
    notification.active = true
    notification_show.v = true
    notification.started = game_ms()
    notification.ride_money = money
    notification.session_money = tonumber(cfg.session.money) or 0
    notification.day_money = tonumber(cfg.day.money) or 0
end

local function reset_order_notify()
    order_notify.pickup_seen   = false
    order_notify.awaiting_dest = false
    order_notify.dest_shown    = false
end

local function notification_alpha()
    if not notification.active then return 0 end
    local elapsed = math.max(0, game_ms() - notification.started)
    if elapsed >= NOTIFY_DURATION then
        notification.active = false
        notification_show.v = false
        return 0
    end
    local function smoothstep(t)
        t = math.max(0, math.min(1, t))
        return t * t * (3 - 2 * t)
    end
    if elapsed < NOTIFY_FADE_IN then
        return smoothstep(elapsed / NOTIFY_FADE_IN)
    end
    local remaining = NOTIFY_DURATION - elapsed
    if remaining < NOTIFY_FADE_OUT then
        return smoothstep(remaining / NOTIFY_FADE_OUT)
    end
    return 1
end

local fontsize, fontsizeBig
local fontsizeNotify, fontsizeNotifyBig

local function now()   return os.time() end
local function today() return os.date('%Y-%m-%d') end

local history     = {}
local history_rev = 0

local function history_file()
    return script_base() .. '\\config\\TaxiHelper_history.json'
end

local function read_history_json(path)
    if type(decodeJson) ~= 'function' then return nil end
    local f = io.open(path, 'rb')
    if not f then return nil end
    local data = f:read('*a')
    f:close()
    local ok, decoded = pcall(decodeJson, data or '')
    if ok and type(decoded) == 'table' then return decoded end
    return nil
end

local function history_save()
    if type(encodeJson) ~= 'function' then return false end
    local ok, data = pcall(encodeJson, history)
    if not ok or type(data) ~= 'string' then return false end
    local path = history_file()
    local tmp, backup = path .. '.tmp', path .. '.bak'
    local f = io.open(tmp, 'wb')
    if not f then return false end
    local written = f:write(data)
    local closed = f:close()
    if not written or not closed then os.remove(tmp); return false end
    if read_history_json(path) then
        local src, dst = io.open(path, 'rb'), io.open(backup, 'wb')
        if src and dst then
            local old = src:read('*a')
            dst:write(old or '')
        end
        if src then src:close() end
        if dst then dst:close() end
    end
    os.remove(path)
    if os.rename(tmp, path) then return true end
    local src = io.open(tmp, 'rb')
    local dst = io.open(path, 'wb')
    if src and dst then
        local payload = src:read('*a')
        local good = dst:write(payload or '')
        src:close(); dst:close(); os.remove(tmp)
        return good and true or false
    end
    if src then src:close() end
    if dst then dst:close() end
    os.remove(tmp)
    return false
end

local function history_load()
    history = read_history_json(history_file())
           or read_history_json(history_file() .. '.bak')
           or {}
    history_rev = history_rev + 1
end

local function history_sync()
    local d = cfg.day.date
    if type(d) ~= 'string' or d == '' then return end
    local r = {
        rides  = tonumber(cfg.day.rides) or 0,
        money  = tonumber(cfg.day.money) or 0,
        worked = tonumber(cfg.day.worked) or 0,
        boxes  = tonumber(cfg.day.boxes) or 0,
        coins  = tonumber(cfg.day.coins) or 0,
        tips   = tonumber(cfg.day.tips) or 0
    }
    local o = history[d]
    if o and o.rides == r.rides and o.money == r.money and o.worked == r.worked
        and o.boxes == r.boxes and o.coins == r.coins and o.tips == r.tips then
        return
    end
    history[d] = r
    history_rev = history_rev + 1
    history_save()
end

local function save()
    cfg.window.show = show.v
    inicfg.save(cfg, config_path)
    history_sync()
end

-- === Таксометр: реальный доход в реальном времени ===
local METER_DRAW_LINGER = 12000
local METER_MIN_COEFF   = 0.1
local METER_MAX_COEFF   = 500

local meter = {
    type = '',
    active = false,
    base = 0,
    peak = 0,
    timer = 0,
    started = 0,
    last_base = 0,
    last_end = 0,
    last_seen = 0,
    paid = 0,
    paid_ms = 0,
    car = '',
}

local meter_data = {}

local meter_show = imgui.ImBool(cfg.meter.show == true or cfg.meter.show == 'true' or cfg.meter.show == 1)
local meter_edit = false

local function meter_file()
    return script_base() .. '\\config\\TaxiHelper_meter.json'
end

local function meter_save()
    if type(encodeJson) ~= 'function' then return end
    local ok, data = pcall(encodeJson, meter_data)
    if not ok or type(data) ~= 'string' then return end
    local path = meter_file()
    local tmp = path .. '.tmp'
    local f = io.open(tmp, 'wb')
    if not f then return end
    local written = f:write(data)
    local closed = f:close()
    if not written or not closed then os.remove(tmp) return end
    os.remove(path)
    if not os.rename(tmp, path) then os.remove(tmp) end
end

local function meter_load()
    meter_data = {}
    if type(decodeJson) ~= 'function' then return end
    local f = io.open(meter_file(), 'rb')
    if not f then return end
    local data = f:read('*a')
    f:close()
    local ok, parsed = pcall(decodeJson, data or '')
    if not ok or type(parsed) ~= 'table' then return end
    for car, rec in pairs(parsed) do
        if type(rec) == 'table' and tonumber(rec.k) then
            meter_data[tostring(car)] = { k = tonumber(rec.k), n = math.max(1, math.floor(tonumber(rec.n) or 1)) }
        end
    end
end

local function meter_coeff_str(k)
    k = tonumber(k) or 0
    if k <= 0 then return '--' end
    local s = string.format('%.4f', k)
    s = s:gsub('0+$', ''):gsub('%.$', '')
    return s
end

function meter_car_display(car)
    car = tostring(car or '')
    if car == '' then return '' end
    local valid = true
    local i, len = 1, #car
    while i <= len do
        local b = car:byte(i)
        if b < 0x80 then
            i = i + 1
        elseif b >= 0xC2 and b <= 0xDF then
            local b2 = car:byte(i + 1)
            if not b2 or b2 < 0x80 or b2 > 0xBF then valid = false break end
            i = i + 2
        elseif b >= 0xE0 and b <= 0xEF then
            local b2, b3 = car:byte(i + 1), car:byte(i + 2)
            if not b2 or not b3 or b2 < 0x80 or b2 > 0xBF or b3 < 0x80 or b3 > 0xBF then
                valid = false
                break
            end
            i = i + 3
        else
            valid = false
            break
        end
    end
    if valid then return car end
    local ok, converted = pcall(u8, car)
    if ok and type(converted) == 'string' and converted ~= '' then return converted end
    return car
end

local function meter_short_money(n)
    n = tonumber(n) or 0
    if n >= 1000000000 then return string.format('%.1fB', n / 1000000000) end
    if n >= 1000000 then return string.format('%.1fM', n / 1000000) end
    if n >= 1000 then return string.format('%.0fK', n / 1000) end
    return tostring(math.floor(n))
end

local function meter_saved_coeff()
    if meter.car ~= '' then
        local rec = meter_data[meter.car]
        if rec and rec.k then return rec.k end
    end
    return 0
end

local function meter_active_coeff()
    if uib.meter_auto.v then
        local k = meter_saved_coeff()
        if k > 0 then return k end
        if meter.car == '' then return tonumber(cfg.ui.meter_coeff) or 0 end
        return 0
    end
    return tonumber(cfg.ui.meter_coeff) or 0
end

local function meter_sync_input()
    if not TaxiHelperUi or not TaxiHelperUi.meterInput then return end
    local k = tonumber(cfg.ui.meter_coeff) or 0
    TaxiHelperUi.meterInput.v = (k > 0) and string.format('%.4f', k) or ''
end

local function meter_calibrate(paid)
    paid = tonumber(paid) or 0
    if paid <= 0 then return end
    if meter.paid_ms > 0 and game_ms() - meter.paid_ms < 5000 then return end
    local base = math.max(meter.base or 0, meter.peak or 0, meter.last_base or 0)
    if base <= 0 then return end
    local fresh = (meter.last_end > 0 and game_ms() - meter.last_end <= 90000)
        or (meter.active and base > 0)
    if not fresh then return end
    local k = paid / base
    if k < METER_MIN_COEFF or k > METER_MAX_COEFF then return end
    meter.paid = paid
    meter.paid_ms = game_ms()
    if meter.car ~= '' then
        local rec = meter_data[meter.car]
        meter_data[meter.car] = { k = k, n = (rec and rec.n or 0) + 1 }
        meter_save()
        event_add(string.format('Таксометр: %s, коэффициент x%s', meter.car, meter_coeff_str(k)))
    end
    if uib.meter_auto.v then
        cfg.ui.meter_coeff = k
        meter_sync_input()
    end
    save()
end

local function meter_handle_cef(str)
    if not str then return end
    if str:find('customizedCounter.initializeType', 1, true) then
        local payload = str:match('`(.-)`') or ''
        meter.type = payload:match('"([^"]*)"') or ''
        if meter.type ~= 'taxi' then
            meter.active = false
            meter.base = 0
            meter.peak = 0
        end
        return
    end
    if str:find('customizedCounter.initializeCounter', 1, true) then
        if meter.type ~= 'taxi' then return end
        local payload = str:match('`(.-)`') or ''
        local v = tonumber(payload:match('"(%d+)"') or payload:match('(%d+)'))
        if not v then return end
        if v == 0 and not meter.active then
            meter.started = game_ms()
            meter.paid, meter.paid_ms = 0, 0
        elseif v > 0 and not meter.active then
            meter.active = true
            meter.started = game_ms()
        end
        meter.base = v
        if v > meter.peak then meter.peak = v end
        meter.last_seen = game_ms()
        return
    end
    if str:find('customizedCounter.initializeTimerRevert', 1, true) then
        if meter.type ~= 'taxi' then return end
        local payload = str:match('`(.-)`') or ''
        meter.timer = tonumber(payload:match('(%d+)')) or meter.timer
        return
    end
    if str:find('arizonahud.updateCustomizedCounterVisibility', 1, true) then
        local payload = str:match('`(.-)`') or ''
        local visible = payload:find('true', 1, true) ~= nil
        if visible then
            if not meter.active then
                meter.active = true
                meter.base = 0
                meter.peak = 0
                meter.started = game_ms()
                meter.paid, meter.paid_ms = 0, 0
                meter.last_seen = game_ms()
            end
        elseif meter.active then
            meter.active = false
            meter.last_base = math.max(meter.base, meter.peak)
            meter.last_end = game_ms()
        end
        if not visible then meter.type = '' end
        return
    end
    if str:find('arizonaDriver.initializeDriver', 1, true) then
        local payload = str:match('`(.-)`') or ''
        local car = payload:match('"car"%s*:%s*"([^"]*)"')
        if car and car ~= '' then
            meter.car = car
            meter_sync_input()
        end
    end
end

local function reset_day_rewards()
    cfg.day.boxes     = 0
    cfg.day.coins     = 0
    cfg.day.tips      = 0
    cfg.day.tips_cash = 0
end

local function check_new_day()
    local d = today()
    if cfg.day.date ~= d then
        if work_segment_start > 0 then
            local midnight = os.time({year=tonumber(d:sub(1,4)), month=tonumber(d:sub(6,7)), day=tonumber(d:sub(9,10)), hour=0, min=0, sec=0})
            local old_end = math.min(now(), midnight)
            if old_end > work_segment_start then
                cfg.day.worked = (tonumber(cfg.day.worked) or 0) + old_end - work_segment_start
                work_segment_start = old_end
            end
            cfg.session.unfinished = 0
            last_unfinished_save = now()
        end
        history_sync()
        cfg.day.date   = d
        cfg.day.rides  = 0
        cfg.day.money  = 0
        cfg.day.worked = 0
        reset_day_rewards()
        save()
    end
end

local function add_ride(money)
    meter_calibrate(money)
    check_new_day()
    cfg.session.rides     = (tonumber(cfg.session.rides) or 0) + 1
    cfg.session.money     = (tonumber(cfg.session.money) or 0) + money
    cfg.session.best_ride = tonumber(cfg.session.best_ride) or 0
    if money > cfg.session.best_ride then
        cfg.session.best_ride = money
    end
    cfg.day.rides = (tonumber(cfg.day.rides) or 0) + 1
    cfg.day.money = (tonumber(cfg.day.money) or 0) + money
    save()
    event_add(string.format("Поездка завершена: $%s", tostring(math.floor(money))))
    show_ride_notification(money)
    local mb = math.max(meter.base or 0, meter.peak or 0, meter.last_base or 0)
    local mk = meter_active_coeff()
    notification.meter_base = mb
    notification.meter_k = mk
    notification.meter_income = (mk > 0 and mb > 0) and math.floor(mb * mk + 0.5) or 0
end

local function finish_work_interval()
    if session_start > 0 then
        check_new_day()
        cfg.day.worked = (tonumber(cfg.day.worked) or 0) + math.max(0, now() - work_segment_start)
        session_start = 0
        work_segment_start = 0
    end
    cfg.session.unfinished = 0
    last_unfinished_save = 0
end

local function reset_session()
    cfg.session.rides      = 0
    cfg.session.money      = 0
    cfg.session.best_ride  = 0
    cfg.session.unfinished = 0
    session_start          = 0
    work_segment_start     = 0
    pending_deliveries     = {}
    waiting_payment        = false
    session_elapsed        = 0
    last_unfinished_save   = 0
    pending_boxes          = 0
    reset_order_notify()
    save()
end

local function reset_day()
    cfg.day.date   = today()
    cfg.day.rides  = 0
    cfg.day.money  = 0
    cfg.day.worked = 0
    reset_day_rewards()
    save()
end

local function format_money(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    while true do
        local r, k = s:gsub('^(-?%d+)(%d%d%d)', '%1.%2')
        s = r
        if k == 0 then break end
    end
    return s
end

TaxiHelperUi = {}
TaxiHelperUi.distanceInput = imgui.ImBuffer(32)
TaxiHelperUi.distanceInput.v = format_money(cfg.ui.max_distance or 3500)
TaxiHelperUi.meterInput = imgui.ImBuffer(16)
do
    local k = tonumber(cfg.ui.meter_coeff) or 0
    TaxiHelperUi.meterInput.v = (k > 0) and string.format('%.4f', k) or ''
end
TaxiHelperUi.meterDirty = false
TaxiHelperUi.numericEditActive = { goal_amount = false, max_distance = false }
TaxiHelperUi.numericDirty = { goal_amount = false, max_distance = false }

function TaxiHelperUi.parseNumber(value)
    local digits = tostring(value or ''):gsub('[^%d]', '')
    if digits == '' then return 0 end
    return tonumber(digits) or 0
end

local function format_time(sec)
    sec = math.floor(tonumber(sec) or 0)
    return string.format('%d:%02d:%02d',
        math.floor(sec / 3600),
        math.floor((sec % 3600) / 60),
        sec % 60)
end

local function draw_money(value)
    imgui.TextColored(DOLLAR_COLOR, '$')
    imgui.SameLine(nil, 0)
    imgui.Text(' ' .. format_money(value))
end

local function utf8_chars(s)
    local t = {}
    for ch in s:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
        t[#t + 1] = ch
    end
    return t
end

local header_cache = {}

local function checkered_header(text)
    local chars = header_cache[text]
    if not chars then
        chars = utf8_chars(text)
        header_cache[text] = chars
    end
    local win_w  = imgui.GetWindowWidth()
    local text_w = imgui.CalcTextSize(text).x
    imgui.SetCursorPosX((win_w - text_w) / 2)
    for i, ch in ipairs(chars) do
        if ch == ' ' then
            imgui.Text(' ')
        else
            imgui.TextColored((i % 2 == 1) and TAXI_YELLOW or TAXI_WHITE, ch)
        end
        imgui.SameLine(nil, 0)
    end
    imgui.NewLine()
end

local function colored_centered_header(text, color)
    local win_w = imgui.GetWindowWidth()
    imgui.SetCursorPosX((win_w - imgui.CalcTextSize(text).x) / 2)
    imgui.PushStyleColor(imgui.Col.Text, color)
    imgui.Text(text)
    imgui.PopStyleColor()
end

local function colored_separator(r, g, b)
    imgui.Dummy(imgui.ImVec2(0, SEP_PAD_TOP))
    local x = imgui.GetCursorScreenPos().x
    local y = imgui.GetCursorScreenPos().y
    imgui.GetWindowDrawList():AddLine(
        imgui.ImVec2(x, y),
        imgui.ImVec2(x + imgui.GetWindowWidth(), y),
        imgui.ImColor(r, g, b, 255):GetU32(),
        1.5
    )
    imgui.Dummy(imgui.ImVec2(0, SEP_PAD_BOTTOM))
end

local function clean_text(text)
    return text and tostring(text):gsub('{%x%x%x%x%x%x}', '') or ''
end

local REWARD_ITEM_IDS = {
    [10429] = 'coins',
    [10428] = 'tips',
}

local REWARD_WINDOW_MS = 8000
local last_delivery_ms = -1000000
local pending_rewards  = {}
local last_reward_key = ''
local last_reward_ms = -100000

local function is_xp_entry(info)
    return tonumber(info.id) == 91780 or tonumber(info.imageId) == 1030
end

local function classify_reward(info)
    if is_xp_entry(info) then return nil end
    local id  = tonumber(info.id)
    local img = tonumber(info.imageId)
    if id and REWARD_ITEM_IDS[id] then return REWARD_ITEM_IDS[id] end
    if img and REWARD_ITEM_IDS[img] then return REWARD_ITEM_IDS[img] end
    return nil
end

local function commit_reward(kind, amount, is_cash)
    check_new_day()
    cfg.day[kind] = (tonumber(cfg.day[kind]) or 0) + amount
    if is_cash then cfg.day.tips_cash = 1 end
    rewards_dirty = true
    local name = kind == 'coins' and 'Монеты' or (kind == 'tips' and 'Чаевые' or 'Награда')
    event_add(name .. ': +' .. tostring(amount))
end

local function queue_reward(kind, amount, is_cash)
    local t = game_ms()
    if t - last_delivery_ms <= REWARD_WINDOW_MS then
        commit_reward(kind, amount, is_cash)
    else
        pending_rewards[#pending_rewards + 1] = { t = t, kind = kind, amount = amount, cash = is_cash }
        if #pending_rewards > 30 then table.remove(pending_rewards, 1) end
    end
end

function on_ride_delivered()
    local t = game_ms()
    last_delivery_ms = t
    for _, r in ipairs(pending_rewards) do
        if t - r.t <= REWARD_WINDOW_MS then
            commit_reward(r.kind, r.amount, r.cash)
        end
    end
    pending_rewards = {}
end

local function handle_informer(payload)
    if type(decodeJson) ~= 'function' then return end
    local ok, data = pcall(decodeJson, payload)
    if not ok or type(data) ~= 'table' then return end
    for _, info in ipairs(data) do
        if type(info) == 'table' and type(info.name) == 'string' then
            local tag  = tostring(info.tag or '')
            local gain = tonumber(tag:match('^%+(%d+)'))
            local kind = classify_reward(info)
            local amount, is_cash = gain, false
            if kind and amount and amount > 0 then
                local key = tostring(kind) .. ':' .. tostring(info.imageId or '') .. ':' ..
                            tostring(info.id or '') .. ':' .. tostring(tag) .. ':' .. tostring(amount)
                local t = game_ms()
                if key ~= last_reward_key or t - last_reward_ms > 900 then
                    queue_reward(kind, amount, is_cash)
                    last_reward_key = key
                    last_reward_ms = t
                end
            end
        end
    end
end

-- === Pickup > destination детект (без плашек, только чат) ===
function sampev.onSetRaceCheckpoint(checkpointType, position, nextPosition, radius)
    if catching and not busy then
        order_notify.pickup_seen = true
        return
    end
    if busy then
        if not order_notify.pickup_seen then
            order_notify.pickup_seen = true
            return
        end
        if order_notify.awaiting_dest then
            order_notify.awaiting_dest = false
            order_notify.dest_shown = true
            local loc = get_location(position.x, position.y)
            local px, py = 0, 0
            if playerPed then
                local ok, x, y = pcall(getCharCoordinates, playerPed)
                if ok and x and y then px, py = x, y end
            end
            local dx, dy = position.x - px, position.y - py
            local dist = math.sqrt(dx * dx + dy * dy)
            AHKMessage(('Клиент в машине > %s, ехать %s'):format(loc, chat_distance(dist)), 0x00FFFF)
        end
    end
end

function sampev.onDisableRaceCheckpoint()
    if busy and not order_notify.dest_shown then
        order_notify.awaiting_dest = true
    end
end

function setActive(state, reason)
    if active == state then return end
    active = state
    busy, catching = false, false
    orders, lastPicked = {}, nil
    lastPickedDist = 0
    order_is_bot, order_seen_at, order_retry_at = {}, {}, {}
    order_collect_start, order_collect_until = 0, 0
    reset_order_notify()
    local suffix = reason and (' (' .. reason .. ')') or ''
    if active then
        if uib.auto_catch.v then
            AHKMessage('Ловля ON - ожидание заказов' .. suffix, 0x00FF00)
        else
            AHKMessage('Автоловля отключена в настройках' .. suffix, 0xFFAA00)
        end
    else
        AHKMessage('Ловля OFF' .. suffix, 0xFF0000)
    end
end

function pickBest()
    if not active or not uib.auto_catch.v or busy or catching then return end
    local current = game_ms()
    if uib.catch_mode.v == 2 and current < order_collect_until then return end
    order_collect_start, order_collect_until = 0, 0
    local bestId, bestDist
    for oid, dist in pairs(orders) do
        local last_seen = order_seen_at[oid] or current
        if current - last_seen > ORDER_STALE_MS then
            orders[oid] = nil
            order_is_bot[oid] = nil
            order_seen_at[oid] = nil
            order_retry_at[oid] = nil
        elseif (not uib.bot_only.v or order_is_bot[oid] == true)
           and (order_retry_at[oid] or 0) <= current then
            if not bestDist or (NEAREST and dist < bestDist) then
                bestId, bestDist = oid, dist
                if not NEAREST then break end
            end
        end
    end
    if bestId then
        lastPicked = bestId
        lastPickedDist = bestDist
        catching = true
        catchStart = current
        reset_order_notify()
        sendcef('pickOrderWorker|' .. bestId)
        AHKMessage(('Ловлю #%d (%d м)'):format(bestId, bestDist), 0xFFFF00)
    end
end

local function onCef(str)
    if not active then return end
    if str:find('event.arizonaDriver.initializeClearOrders', 1, true) then
        return
    end
    if str:find('event.arizonaDriver.initializeOrders', 1, true) then
        local max_dist = tonumber(uib.max_distance.v) or 3500
        local current = game_ms()
        local seen = 0
        local eligible_seen = false
        local function register_order(obj)
            if type(obj) ~= 'table' then return end
            local oid = tonumber(obj.id)
            local dist = tonumber(obj.distance)
            local rating = tonumber(obj.rating)
            local free = tonumber(obj.active) == 0
            if oid == nil then return end
            seen = seen + 1
            if dist and free and dist <= max_dist then
                orders[oid] = dist
                order_is_bot[oid] = rating ~= nil and rating >= 4.999
                order_seen_at[oid] = current
                if not uib.bot_only.v or order_is_bot[oid] then
                    eligible_seen = true
                end
            else
                orders[oid] = nil
                order_is_bot[oid] = nil
                order_seen_at[oid] = nil
                order_retry_at[oid] = nil
            end
        end
        local payload = str:match('`(.-)`')
        if payload and type(decodeJson) == 'function' then
            local ok, parsed = pcall(decodeJson, payload)
            if ok and type(parsed) == 'table' then
                local function walk(node, depth)
                    if depth > 5 or type(node) ~= 'table' then return end
                    if node.id ~= nil then
                        register_order(node)
                    else
                        for _, item in pairs(node) do walk(item, depth + 1) end
                    end
                end
                walk(parsed, 1)
            end
        end
        if seen == 0 then
            for obj in str:gmatch('{(.-)}') do
                register_order({
                    id = obj:match('"id"%s*:%s*(%d+)'),
                    rating = obj:match('"rating"%s*:%s*([%d%.]+)'),
                    distance = obj:match('"distance"%s*:%s*(%d+)'),
                    active = obj:match('"active"%s*:%s*(%d+)')
                })
            end
        end
        if eligible_seen and uib.auto_catch.v and not busy and not catching then
            if uib.catch_mode.v == 1 then
                order_collect_start, order_collect_until = 0, 0
                pickBest()
            elseif order_collect_until == 0 or current >= order_collect_until then
                order_collect_start = current
                order_collect_until = current + ORDER_COLLECT_MS
            end
        end
        return
    end
    if str:find('initializeDriverPage', 1, true) and str:find('"order"', 1, true) then
        if not busy then
            busy = true
            catching = false
            if uib.sound_on.v then TaxiHelperSound.play_selected() end
            local accepted_dist = lastPickedDist
            if lastPicked then
                orders[lastPicked] = nil
                order_is_bot[lastPicked] = nil
                order_seen_at[lastPicked] = nil
                order_retry_at[lastPicked] = nil
            end
            lastPicked = nil
            lastPickedDist = 0
            order_notify.awaiting_dest = false
            order_notify.dest_shown = false
            if accepted_dist and accepted_dist > 0 then
                AHKMessage(('Заказ пойман > ехать %s'):format(chat_distance(accepted_dist)), 0x00FFFF)
            else
                AHKMessage('Заказ пойман -> везём', 0x00FF00)
            end
        end
        return
    end
end

local function process_cef(str)
    meter_handle_cef(str)
    onCef(str)
    if str:find('damageInformer.initializeDamageInfo', 1, true) then
        local payload = str:match('`(.*)`')
        if payload then handle_informer(payload) end
    end
end

addEventHandler('onReceivePacket', function(id, bs)
    if id ~= 220 then return end
    raknetBitStreamIgnoreBits(bs, 8)
    if raknetBitStreamReadInt8(bs) == 17 then
        raknetBitStreamIgnoreBits(bs, 32)
        local len = raknetBitStreamReadInt16(bs)
        local enc = raknetBitStreamReadInt8(bs)
        local str = (enc ~= 0) and raknetBitStreamDecodeString(bs, len + enc)
                                or raknetBitStreamReadString(bs, len)
        if str then
            local ok, err = pcall(process_cef, str)
            if not ok then print('[TaxiHelper] CEF: ' .. tostring(err)) end
        end
    end
    raknetBitStreamResetReadPointer(bs)
end)

function sampev.onServerMessage(_, text)
    local clean = clean_text(text)

    if AUTO and active then
        if clean:find('Вы закончили работу таксистом', 1, true) then
            setActive(false, 'работа закончена')
        elseif clean:find('Вы прервали заказ', 1, true) then
            busy, catching = false, false
            reset_order_notify()
            if lastPicked then orders[lastPicked] = nil end
            lastPicked = nil
            lastPickedDist = 0
            AHKMessage('Заказ прерван -> ждём новый', 0xFFAA00)
            pickBest()
        elseif clean:find('Вы не смогли вовремя доставить', 1, true)
            or clean:find('К сожалению заказ отменили', 1, true) then
            local was_busy = busy or catching
            busy, catching = false, false
            reset_order_notify()
            if lastPicked then
                orders[lastPicked] = nil
                order_is_bot[lastPicked] = nil
                order_seen_at[lastPicked] = nil
                order_retry_at[lastPicked] = nil
            end
            lastPicked = nil
            lastPickedDist = 0
            pending_boxes = 0
            if was_busy then
                AHKMessage('Время доставки истекло - ищем новый заказ', 0xFFAA00)
            end
            pickBest()
        end
    end

    if clean:find('Вы начали работу таксистом') then
        if session_start > 0 then finish_work_interval() end
        cfg.session.rides      = 0
        cfg.session.money      = 0
        cfg.session.best_ride  = 0
        cfg.session.unfinished = 0
        session_elapsed        = 0
        pending_boxes          = 0
        session_start          = os.time()
        work_segment_start     = session_start
        pending_deliveries     = {}
        waiting_payment        = false
        last_unfinished_save   = session_start
        reset_order_notify()
        event_add("Смена началась")
        save()
    elseif clean:find('Вы закончили работу таксистом') then
        finish_work_interval()
        cfg.session.rides      = 0
        cfg.session.money      = 0
        cfg.session.best_ride  = 0
        cfg.session.unfinished = 0
        session_start          = 0
        work_segment_start     = 0
        pending_deliveries     = {}
        waiting_payment        = false
        session_elapsed        = 0
        last_unfinished_save   = 0
        pending_boxes          = 0
        reset_order_notify()
        event_add("Смена завершена")
        save()
    elseif clean:find('Ларцов за выполненный заказ') then
        local n = clean:match('%+(%d+)%s*Ларцов')
        if n then pending_boxes = tonumber(n) end
    elseif clean:find('Вы доставили клиента по имени') then
        if active and busy then
            busy = false
            catching = false
            lastPicked = nil
            lastPickedDist = 0
            reset_order_notify()
            AHKMessage('Доставил -> ждём заказ', 0x00FF00)
            pickBest()
        end
        local t = now()
        pending_deliveries[#pending_deliveries + 1] = t
        if #pending_deliveries > MAX_PENDING_PAYMENTS then
            table.remove(pending_deliveries, 1)
        end
        waiting_payment  = true
        payment_deadline = t + PAYMENT_TIMEOUT
        on_ride_delivered()
    elseif waiting_payment then
        local m = clean:match('Клиент оплатил:%s*[^%d]*([%d%.%s,]+)')
        if m then
            local amount = tonumber((m:gsub('%s+', ''):gsub('%.', ''):gsub(',', '')))
            local t = now()
            local ms = game_ms()
            local duplicate = (last_payment_text == clean and ms - last_payment_ms < 350)
            if amount and amount >= 0 and not duplicate and #pending_deliveries > 0 then
                table.remove(pending_deliveries, 1)
                add_ride(amount)
                last_payment_text, last_payment_ms = clean, ms
                if pending_boxes > 0 then
                    check_new_day()
                    cfg.day.boxes = (tonumber(cfg.day.boxes) or 0) + pending_boxes
                    rewards_dirty = true
                    pending_boxes = 0
                end
            end
            waiting_payment = #pending_deliveries > 0
            payment_deadline = t + PAYMENT_TIMEOUT
        end
    end
end

function sampev.onShowDialog(id, style, title, b1, b2, text)
    if AUTO and (id == DIALOG_START or (title and title:find('Начало работы', 1, true))
              or (text and text:find('Введите название вашего такси', 1, true))) then
        setActive(true, 'начало работы')
        return
    end
    if not active or not uib.auto_catch.v then return end
    if id == DIALOG_CONFIRM and text:find('Вы хотите принять этот вызов', 1, true) then
        sampSendDialogResponse(id, 1, -1, '')
        return false
    end
    if text:find('Заказ уже принят или отменён', 1, true) then
        sampSendDialogResponse(id, 1, -1, '')
        if lastPicked then
            orders[lastPicked] = nil
            order_is_bot[lastPicked] = nil
            order_seen_at[lastPicked] = nil
            order_retry_at[lastPicked] = nil
            lastPicked = nil
            lastPickedDist = 0
        end
        reset_order_notify()
        if catching and not busy then
            catching = false
            pickBest()
        end
        return false
    end
end

function sampev.onSendDialogResponse(id, button, list, input)
    if AUTO and id == DIALOG_START and button == 0 then
        setActive(false, 'старт отменён')
    end
end

function sendcef(str)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt16(bs, #str)
    raknetBitStreamWriteString(bs, str)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamResetReadPointer(bs)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end

function AHKMessage(text, color)
    sampAddChatMessage('{AA66FF}[Taxi Helper]{FFFFFF} ' .. tostring(text), color or -1)
end

UPDATE_CURRENT_VERSION = '2.5.1'
do
    local ok_v, v = pcall(function() return thisScript().version end)
    if ok_v and type(v) == 'string' and v:match('^%d+%.%d+') then UPDATE_CURRENT_VERSION = v end
end
UPDATE_INFO_URL = 'https://raw.githubusercontent.com/realHansel/TaxiHelper/main/info.upd'
UPDATE_SCRIPT_URL = 'https://raw.githubusercontent.com/realHansel/TaxiHelper/main/TaxiHelper.lua'
UPDATE_DLSTATUS = require('moonloader').download_status
update_state = 'idle'
update_latest = ''
update_changelog = {}
update_dialog_open = imgui.ImBool(false)
update_error = ''
update_started = 0
update_token = 0
update_ready = false
update_temp_script = nil

local function update_is_configured()
    return type(UPDATE_INFO_URL) == 'string' and UPDATE_INFO_URL:match('^https://')
       and type(UPDATE_SCRIPT_URL) == 'string' and UPDATE_SCRIPT_URL:match('^https://')
end

local function update_read_file(path)
    local f = io.open(path, 'rb')
    if not f then return nil end
    local data = f:read('*a')
    f:close()
    return data
end

local function update_newer(remote, local_version)
    if type(remote) ~= 'string' or not remote:match('^%d+%.%d+%.?%d*$') then return false end
    if type(local_version) ~= 'string' then return false end
    local a, b = {}, {}
    for p in remote:gmatch('%d+') do a[#a + 1] = tonumber(p) end
    for p in local_version:gmatch('%d+') do b[#b + 1] = tonumber(p) end
    for i = 1, math.max(#a, #b) do
        local x, y = a[i] or 0, b[i] or 0
        if x > y then return true end
        if x < y then return false end
    end
    return false
end

local function update_fail(message)
    update_state = 'error'
    update_error = message or 'Неизвестная ошибка'
    update_ready = false
    print('[TaxiHelper / Updater] ' .. update_error)
end

local function update_check()
    if update_state == 'checking' or update_state == 'downloading' or update_state == 'installing' then return end
    if not update_is_configured() then
        update_state = 'unconfigured'
        return
    end
    if type(downloadUrlToFile) ~= 'function' then
        update_fail('MoonLoader downloadUrlToFile недоступен')
        return
    end
    update_state = 'checking'
    update_error = ''
    update_changelog = {}
    update_dialog_open.v = false
    update_token = update_token + 1
    local token = update_token
    update_started = os.time()
    local path = script_base() .. '\\config\\TaxiHelper_update_info.tmp'
    os.remove(path)
    local url = UPDATE_INFO_URL .. (UPDATE_INFO_URL:find('?', 1, true) and '&' or '?') .. 't=' .. tostring(os.time())
    local ok, err = pcall(function()
        downloadUrlToFile(url, path, function(id, status)
            if token ~= update_token or update_state ~= 'checking' then return end
            if status == UPDATE_DLSTATUS.STATUS_ENDDOWNLOADDATA or status == UPDATE_DLSTATUS.STATUSEX_ENDDOWNLOAD then
                local contents = update_read_file(path)
                if not contents or #contents > 8192 or #contents < 10 then
                    update_fail('Не удалось получить файл версии')
                    os.remove(path)
                    return
                end
                local parsed_ok, result = pcall(decodeJson, contents)
                os.remove(path)
                if not parsed_ok or type(result) ~= 'table' or type(result.version) ~= 'string' or not result.version:match('^%d+%.%d+%.?%d*$') then
                    update_fail('Некорректный info.upd')
                    return
                end
                update_latest = result.version
                update_changelog = {}
                if type(result.changelog) == 'table' then
                    for i = 1, math.min(#result.changelog, 30) do
                        local entry = result.changelog[i]
                        if type(entry) == 'string' and #entry > 0 then
                            update_changelog[#update_changelog + 1] = entry:sub(1, 800)
                        end
                    end
                elseif type(result.changelog) == 'string' and #result.changelog > 0 then
                    update_changelog[1] = result.changelog:sub(1, 2000)
                end
                update_state = update_newer(update_latest, UPDATE_CURRENT_VERSION) and 'available' or 'current'
            elseif status == UPDATE_DLSTATUS.STATUS_ERROR then
                update_fail('Ошибка загрузки info.upd')
            end
        end)
    end)
    if not ok then update_fail('Не удалось начать проверку: ' .. tostring(err)) end
end

local function update_download()
    if update_state ~= 'available' or not update_is_configured() then return end
    local script = thisScript()
    if not script or type(script.path) ~= 'string' or script.path == '' or not doesFileExist(script.path) then
        update_fail('Не удалось определить путь установленного Lua-файла')
        return
    end
    local script_path = script.path
    update_temp_script = script_path .. '.download'
    os.remove(update_temp_script)
    update_state = 'downloading'
    update_ready = false
    update_started = os.time()
    update_token = update_token + 1
    local token = update_token
    local script_url = UPDATE_SCRIPT_URL .. (UPDATE_SCRIPT_URL:find('?', 1, true) and '&' or '?') .. 't=' .. tostring(os.time())
    local ok, err = pcall(function()
        downloadUrlToFile(script_url, update_temp_script, function(id, status)
            if token ~= update_token or update_state ~= 'downloading' then return end
            if status == UPDATE_DLSTATUS.STATUS_ENDDOWNLOADDATA or status == UPDATE_DLSTATUS.STATUSEX_ENDDOWNLOAD then
                local contents = update_read_file(update_temp_script)
                if not contents or #contents < 10000 or #contents > 1024 * 1024 then
                    update_fail('Скачанный файл отсутствует или имеет неверный размер')
                    return
                end
                local version = contents:match("script_version%s*%(%s*['\"]([%d%.]+)['\"]%s*%)")
                if version ~= update_latest or not contents:find('script_name', 1, true) or not contents:find('Taxi Helper', 1, true) then
                    update_fail('Содержимое обновления не соответствует версии ' .. update_latest)
                    return
                end
                local chunk, syntax_err = loadfile(update_temp_script)
                if not chunk then
                    update_fail('Lua-файл содержит ошибку: ' .. tostring(syntax_err))
                    return
                end
                update_ready = true
            elseif status == UPDATE_DLSTATUS.STATUS_ERROR then
                update_fail('Ошибка скачивания Lua-файла')
            end
        end)
    end)
    if not ok then update_fail('Не удалось начать скачивание: ' .. tostring(err)) end
end

local function update_install()
    local script = thisScript()
    if not script or type(script.path) ~= 'string' then return false, 'Путь Lua-файла недоступен' end
    local path = script.path
    local old_code = update_read_file(path)
    if not old_code or #old_code < 1000 then return false, 'Не удалось прочитать установленную версию' end
    local bak = path .. '.bak'
    local backup_tmp = bak .. '.tmp'
    local f = io.open(backup_tmp, 'wb')
    if not f then return false, 'Не удалось создать резервную копию' end
    local written = f:write(old_code)
    local closed = f:close()
    if not written or not closed then os.remove(backup_tmp); return false, 'Не удалось записать резервную копию' end
    os.remove(bak)
    if not os.rename(backup_tmp, bak) then os.remove(backup_tmp); return false, 'Не удалось сохранить резервную копию' end
    if not update_temp_script or not doesFileExist(update_temp_script) then
        return false, 'Временный файл обновления недоступен'
    end
    local previous = path .. '.previous'
    os.remove(previous)
    local renamed_old = os.rename(path, previous)
    if not renamed_old then return false, 'Не удалось подготовить установленный файл к замене' end
    local renamed_new = os.rename(update_temp_script, path)
    if not renamed_new then
        local restored = os.rename(previous, path)
        if not restored then
            local rollback = io.open(path, 'wb')
            if rollback then rollback:write(old_code); rollback:close() end
        end
        return false, 'Не удалось переместить обновление; прежний файл восстановлен'
    end
    os.remove(previous)
    update_temp_script = nil
    return true
end

local function update_button_text()
    if update_state == 'checking' then return u8'Проверка обновлений...' end
    if update_state == 'available' then return u8'Доступно обновление' .. ' v' .. update_latest end
    if update_state == 'downloading' then return u8'Скачивание...' end
    if update_state == 'installing' then return u8'Установка...' end
    if update_state == 'current' then return u8'Актуальная версия' end
    if update_state == 'unconfigured' then return u8'Обновления не настроены' end
    if update_state == 'error' then return u8'Повторить проверку' end
    return u8'Проверить обновления'
end

local function update_draw_button()
    local pos = imgui.GetCursorScreenPos()
    local window_pos = imgui.GetWindowPos()
    local window_width = imgui.GetWindowWidth()
    local btn_w = 255
    imgui.SetCursorScreenPos(imgui.ImVec2(window_pos.x + window_width - btn_w - 6, pos.y))
    if update_state == 'available' then
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.12, 0.32, 0.17, 0.92))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.17, 0.43, 0.21, 1.0))
    else
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.13, 0.15, 0.17, 0.90))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.18, 0.23, 0.20, 1.0))
    end
    if imgui.Button(update_button_text() .. '##taxi_updater', imgui.ImVec2(btn_w, 28)) then
        if update_state == 'available' then
            update_dialog_open.v = true
        elseif update_state == 'checking' or update_state == 'downloading' or update_state == 'installing' then
        elseif update_state == 'unconfigured' then
            AHKMessage('Ссылка на обновления не настроена.')
        else
            update_check()
        end
    end
    imgui.PopStyleColor(2)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        if update_state == 'error' then
            imgui.Text(u8(update_error))
        else
            imgui.Text(u8'Установлена версия: ' .. UPDATE_CURRENT_VERSION)
        end
        imgui.EndTooltip()
    end
    imgui.SetCursorScreenPos(imgui.ImVec2(pos.x, pos.y + 36))
end

local function update_draw_dialog()
    if not update_dialog_open.v or not menu_open.v then return end
    local io = imgui.GetIO()
    imgui.SetNextWindowSize(imgui.ImVec2(520, 350), imgui.Cond.Always)
    imgui.SetNextWindowPos(imgui.ImVec2(io.DisplaySize.x * 0.5, io.DisplaySize.y * 0.5), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 8)
    imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(18, 16))
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.075, 0.078, 0.085, 0.99))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.20, 0.65, 0.29, 0.90))
    imgui.Begin(u8'##TaxiHelperUpdateDialog', update_dialog_open,
        imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoSavedSettings)
    imgui.PushFont(fontsize)
    imgui.TextColored(imgui.ImVec4(0.26, 0.98, 0.26, 1.0), u8'ДОСТУПНО ОБНОВЛЕНИЕ')
    imgui.Spacing()
    imgui.TextColored(imgui.ImVec4(0.62, 0.64, 0.70, 1.0), u8'Установлена версия: ' .. UPDATE_CURRENT_VERSION)
    imgui.SameLine()
    imgui.TextColored(imgui.ImVec4(0.35, 1.0, 0.35, 1.0), u8'Новая: ' .. update_latest)
    imgui.Spacing()
    imgui.Separator()
    imgui.TextColored(imgui.ImVec4(0.26, 0.98, 0.26, 1.0), u8'Что нового:')
    imgui.BeginChild('##taxi_update_changelog', imgui.ImVec2(0, 162), true)
    if #update_changelog == 0 then
        imgui.TextWrapped(u8'Автор пока не добавил список изменений для этой версии.')
    else
        for i, entry in ipairs(update_changelog) do
            imgui.TextColored(imgui.ImVec4(0.26, 0.98, 0.26, 1.0), tostring(i) .. '.')
            imgui.SameLine(nil, 6)
            imgui.TextWrapped(entry)
            if i < #update_changelog then imgui.Spacing() end
        end
    end
    imgui.EndChild()
    imgui.Spacing()
    if imgui.Button(u8'Позже##taxi_update_later', imgui.ImVec2(130, 34)) then
        update_dialog_open.v = false
    end
    imgui.SameLine()
    if imgui.Button(u8'Установить обновление##taxi_update_install', imgui.ImVec2(230, 34)) then
        update_dialog_open.v = false
        update_download()
    end
    imgui.PopFont()
    imgui.End()
    imgui.PopStyleColor(2)
    imgui.PopStyleVar(2)
end

local function update_tick()
    if (update_state == 'checking' or update_state == 'downloading') and os.time() - update_started > 35 then
        update_token = update_token + 1
        update_fail('Превышено время ожидания ответа сервера')
    end
    if update_ready and update_state == 'downloading' then
        update_ready = false
        update_state = 'installing'
        local ok, err = update_install()
        if ok then
            AHKMessage('Обновление v' .. update_latest .. ' установлено. Перезапускаю скрипт...')
            return true
        end
        update_fail(err)
    end
    return false
end


FA_FONT = nil
FA_ATTEMPTED = false
FA_RANGES = nil
FA_GLYPHS_OK = false
FA_ICON_WARNING = false
FA_URL_ = 'https://raw.githubusercontent.com/FortAwesome/Font-Awesome/v4.7.0/fonts/fontawesome-webfont.ttf'
FA_FONTS_DIR = script_base() .. '\\resource\\fonts'
FA_PATH = FA_FONTS_DIR .. '\\fontawesome-webfont.ttf'
FA_TEMP = FA_PATH .. '.download'
FA_DOWNLOADING = false
FA_DOWNLOAD_CHECKED = false
FA_DLSTATUS = require('moonloader').download_status
FA_DRAW_ERROR_LOGGED = false

local function fa_valid_file(path)
    local f = io.open(path, 'rb')
    if not f then return false end
    local header = f:read(4)
    local size = f:seek('end') or 0
    f:close()
    return size > 20000 and (header == string.char(0, 1, 0, 0) or header == 'OTTO' or header == 'true')
end

local function fa_log(msg)
    if msg:lower():find('error', 1, true) or msg:lower():find('invalid', 1, true) then
        print('[Taxi Helper / Font Awesome] ' .. msg)
    end
end

local function fa_ensure_font()
    if FA_DOWNLOAD_CHECKED then return end
    FA_DOWNLOAD_CHECKED = true
    fa_log('Checking font: ' .. FA_PATH)
    if fa_valid_file(FA_PATH) then
        fa_log('Font file found.')
        return
    end
    if type(downloadUrlToFile) ~= 'function' then
        fa_log('downloadUrlToFile unavailable; install font manually.')
        return
    end
    local dir = FA_FONTS_DIR
    if type(createDirectory) == 'function' then
        pcall(createDirectory, script_base() .. '\\resource')
        pcall(createDirectory, dir)
    end
    os.remove(FA_TEMP)
    FA_DOWNLOADING = true
    fa_log('Font missing; downloading...')
    local ok, err = pcall(function()
        downloadUrlToFile(FA_URL_, FA_TEMP, function(id, status, p1, p2)
            local ds = FA_DLSTATUS
            if ds and status == ds.STATUS_ENDDOWNLOADDATA then
                FA_DOWNLOADING = false
                if fa_valid_file(FA_TEMP) then
                    if not fa_valid_file(FA_PATH) then
                        os.remove(FA_PATH)
                        local renamed = os.rename(FA_TEMP, FA_PATH)
                        if not renamed then
                            fa_log('Could not move downloaded font.')
                            return
                        end
                    else
                        os.remove(FA_TEMP)
                    end
                    fa_log('Font downloaded.')
                else
                    os.remove(FA_TEMP)
                    fa_log('Downloaded font is invalid.')
                end
            elseif ds and (status == ds.STATUS_ERROR or status == ds.STATUSEX_ENDDOWNLOAD) then
                FA_DOWNLOADING = false
                if fa_valid_file(FA_TEMP) then
                    if not fa_valid_file(FA_PATH) then
                        os.remove(FA_PATH)
                        if os.rename(FA_TEMP, FA_PATH) then
                            fa_log('Font downloaded.')
                        else
                            fa_log('Could not move downloaded font.')
                        end
                    else
                        os.remove(FA_TEMP)
                    end
                else
                    os.remove(FA_TEMP)
                    fa_log('Download ended without a valid font.')
                end
            end
        end)
    end)
    if not ok then
        FA_DOWNLOADING = false
        fa_log('Download could not start: ' .. tostring(err))
    end
end

function imgui.OnInitialize()
    imgui.GetIO().IniFilename = nil
    local style = imgui.GetStyle()
    style.WindowRounding      = 10
    style.FrameRounding       = 6
    style.ChildWindowRounding = 8
    style.WindowPadding       = imgui.ImVec2(14, 12)
    style.FramePadding        = imgui.ImVec2(8, 5)
    style.ItemSpacing         = imgui.ImVec2(8, 8)
    style.ItemInnerSpacing    = imgui.ImVec2(6, 4)
    pcall(function()
        style.GrabRounding      = 6
        style.ScrollbarRounding = 6
        style.ScrollbarSize     = 12
        style.WindowTitleAlign  = imgui.ImVec2(0.5, 0.5)
    end)
    local colors = style.Colors
    local col = imgui.Col
    local function set(name, v)
        local idx = col[name]
        if idx ~= nil then colors[idx] = v end
    end
    set('Text',                 imgui.ImVec4(0.93, 0.93, 0.96, 1.00))
    set('TextDisabled',         imgui.ImVec4(0.52, 0.54, 0.60, 1.00))
    set('WindowBg',             imgui.ImVec4(0.075, 0.078, 0.085, 0.78))
    set('ChildWindowBg',        imgui.ImVec4(0.095, 0.098, 0.105, 1.00))
    set('ChildBg',              imgui.ImVec4(0.095, 0.098, 0.105, 1.00))
    set('Border',               imgui.ImVec4(0.20, 0.21, 0.22, 1.00))
    set('TitleBg',              imgui.ImVec4(0.12, 0.12, 0.15, 1.00))
    set('TitleBgActive',        imgui.ImVec4(0.10, 0.13, 0.10, 1.00))
    set('TitleBgCollapsed',     imgui.ImVec4(0.12, 0.12, 0.15, 1.00))
    set('Button',               imgui.ImVec4(0.19, 0.19, 0.24, 1.00))
    set('ButtonHovered',        imgui.ImVec4(0.20, 0.30, 0.20, 1.00))
    set('ButtonActive',         imgui.ImVec4(0.24, 0.40, 0.24, 1.00))
    set('Separator',            imgui.ImVec4(0.24, 0.24, 0.30, 1.00))
    set('FrameBg',              imgui.ImVec4(0.17, 0.17, 0.21, 1.00))
    set('FrameBgHovered',       imgui.ImVec4(0.23, 0.23, 0.29, 1.00))
    set('FrameBgActive',        imgui.ImVec4(0.18, 0.35, 0.18, 1.00))
    set('CheckMark',            imgui.ImVec4(0.26, 0.98, 0.26, 1.00))
    set('ScrollbarBg',          imgui.ImVec4(0.09, 0.09, 0.11, 0.60))
    set('ScrollbarGrab',        imgui.ImVec4(0.30, 0.30, 0.38, 1.00))
    set('ScrollbarGrabHovered', imgui.ImVec4(0.40, 0.40, 0.50, 1.00))
    set('ScrollbarGrabActive',  imgui.ImVec4(0.26, 0.98, 0.26, 1.00))
    set('CloseButton',          imgui.ImVec4(0.19, 0.19, 0.24, 1.00))
    set('CloseButtonHovered',   imgui.ImVec4(0.85, 0.28, 0.28, 1.00))
    set('CloseButtonActive',    imgui.ImVec4(0.95, 0.35, 0.35, 1.00))
end

local function load_font(size)
    local fonts = imgui.GetIO().Fonts
    local path = getFolderPath(0x14) .. '\\trebucbd.ttf'
    if doesFileExist(path) then
        return fonts:AddFontFromFileTTF(path, size, nil, fonts:GetGlyphRangesCyrillic())
    end
    return fonts:AddFontDefault()
end

function imgui.BeforeDrawFrame()
    if not fontsize then
        fontsize    = load_font(17.0)
        fontsizeBig = load_font(22.0)
    end
    if not fontsizeNotify then
        fontsizeNotify    = load_font(19.0)
        fontsizeNotifyBig = load_font(26.0)
    end
    if not FA_ATTEMPTED and not FA_DOWNLOADING then
        FA_ATTEMPTED = true
        local ok, err = pcall(function()
            local ffi = require 'ffi'
            FA_RANGES = imgui.ImGlyphRanges({0xF000, 0xF2FF})
            if not fa_valid_file(FA_PATH) then
                fa_log('Font file not found or invalid: ' .. FA_PATH)
                return
            end
            FA_FONT = imgui.GetIO().Fonts:AddFontFromFileTTF(FA_PATH, 14.0, nil, FA_RANGES)
            if FA_FONT == nil then
                fa_log('AddFontFromFileTTF returned nil')
            else
                fa_log('Font Awesome registered.')
            end
        end)
        if not ok then fa_log('Font initialization error: ' .. tostring(err)) end
    end
end

local ACCENT = imgui.ImVec4(0.26, 0.98, 0.26, 1.00)
local MUTED  = imgui.ImVec4(0.62, 0.64, 0.70, 1.00)

local menu_tab       = 1
local logs_cache     = nil
local logs_cache_rev = -1

local SESSION_ITEMS = {
    { key = 's_rides', label = L.i_rides },
    { key = 's_money', label = L.i_earned },
    { key = 's_avg',   label = L.i_avg },
    { key = 's_time',  label = L.i_time },
}

local DAY_ITEMS = {
    { key = 'd_money',  label = L.i_earned },
    { key = 'd_worked', label = L.i_worked },
    { key = 'd_rides',  label = L.i_rides },
    { key = 'd_boxes',  label = L.i_boxes },
    { key = 'd_coins',  label = L.i_coins },
    { key = 'd_tips',   label = L.i_tips },
    { key = 'd_avg',    label = L.i_avg },
}

local function ui_commit(key)
    cfg.ui[key] = uib[key].v and 1 or 0
    save()
end

local ICONS = {
    rides='\239\134\185',
    earned='\239\131\150',
    avg='\239\135\172',
    time='\239\128\151',
    worked='\239\128\151',
    boxes='\239\134\178',
    coins='\239\131\150',
    tips='\239\129\171',
    stats='\239\130\128',
    notify='\239\131\179',
    move='\239\129\135',
    orders='\239\130\174',
    windows='\239\128\137',
    session='\239\128\135',
    day='\239\129\179',
    settings='\239\128\147',
    history='\239\135\154',
    main='\239\128\149',
    total='\239\131\150',
    date='\239\129\179',
    distance='\239\129\129'
}
local ICON_FALLBACK = {
    rides='R', earned='$', avg='A', time='T', worked='T', boxes='B', coins='C', tips='+',
    stats='S', notify='N', move='M', orders='O', windows='W', session='S', day='D',
    settings='G', history='H', main='S', total='$', date='D', distance='M'
}

local function fa_draw_at(kind, x, y, fallback, color)
    local saved = imgui.GetCursorScreenPos()
    local rendered = false
    FA_GLYPHS_OK = FA_FONT ~= nil
    if FA_FONT and FA_GLYPHS_OK then
        local ok, err = pcall(function()
            imgui.SetCursorScreenPos(imgui.ImVec2(x, y))
            imgui.PushFont(FA_FONT)
            local text_ok, text_err = pcall(imgui.Text, ICONS[kind] or ICONS.stats)
            imgui.PopFont()
            if not text_ok then error(text_err) end
        end)
        rendered = ok
        if not ok and not FA_DRAW_ERROR_LOGGED then
            FA_DRAW_ERROR_LOGGED = true
            fa_log('Icon drawing error: ' .. tostring(err))
        end
    end
    if not rendered then
        if FA_FONT and not FA_GLYPHS_OK and not FA_ICON_WARNING then
            FA_ICON_WARNING = true
            fa_log('Icon glyphs missing; using text fallback.')
        end
        imgui.SetCursorScreenPos(imgui.ImVec2(x, y))
        imgui.Text(fallback or ICON_FALLBACK[kind] or '*')
    end
    imgui.SetCursorScreenPos(saved)
end

local notification_icon_alpha = 1
local function fade_draw_color(color)
    local a = math.floor(color / 0x1000000) % 256
    local rgb = color % 0x1000000
    return math.floor(a * notification_icon_alpha + 0.5) * 0x1000000 + rgb
end

local function draw_icon(kind, color)
    local pos = imgui.GetCursorScreenPos()
    local sz = 21
    local dl = imgui.GetWindowDrawList()
    local fg = fade_draw_color(color or 0xFF44DC66)
    dl:AddRectFilled(imgui.ImVec2(pos.x, pos.y + 1), imgui.ImVec2(pos.x + sz, pos.y + sz + 1), fade_draw_color(0xFF223529), 4)
    dl:AddRect(imgui.ImVec2(pos.x, pos.y + 1), imgui.ImVec2(pos.x + sz, pos.y + sz + 1), fg, 4)
    local glyph_width = 14
    if FA_FONT then
        pcall(function()
            imgui.PushFont(FA_FONT)
            glyph_width = imgui.CalcTextSize(ICONS[kind] or ICONS.stats).x
            imgui.PopFont()
        end)
    end
    local icon_x = pos.x + math.max(1, (sz - glyph_width) / 2)
    fa_draw_at(kind, icon_x, pos.y + 2, ICON_FALLBACK[kind], fg)
    imgui.Dummy(imgui.ImVec2(sz, sz + 2))
end
local function icon_text(kind, label, color)
    draw_icon(kind)
    imgui.SameLine(nil, 7)
    if color then imgui.TextColored(color, label) else imgui.Text(label) end
end
local function icon_kind_for_label(label)
    if label == L.rides or label == L.i_rides then return 'rides' end
    if label == L.earned or label == L.i_earned then return 'earned' end
    if label == L.avg or label == L.i_avg then return 'avg' end
    if label == L.worked or label == L.i_worked then return 'worked' end
    if label == L.session_time or label == L.i_time then return 'time' end
    if label == L.i_boxes then return 'boxes' end
    if label == L.i_coins then return 'coins' end
    if label == L.i_tips then return 'tips' end
    if label == L.opt_stats then return 'stats' end
    if label == L.opt_notify or label == L.sound_on then return 'notify' end
    return 'settings'
end

local function ui_toggle(id, label, state)
    local changed = false
    local ok = pcall(function()
        local pos = imgui.GetCursorScreenPos()
        local w, h = 40, 20
        if imgui.InvisibleButton('##tg_' .. id, imgui.ImVec2(w, h)) then
            state.v = not state.v
            changed = true
        end
        local dl = imgui.GetWindowDrawList()
        local bg = state.v and imgui.ImColor(66, 220, 82, 255):GetU32() or imgui.ImColor(66, 68, 78, 255):GetU32()
        dl:AddRectFilled(imgui.ImVec2(pos.x, pos.y), imgui.ImVec2(pos.x + w, pos.y + h), bg, h / 2, 15)
        local cx = state.v and (pos.x + w - h / 2) or (pos.x + h / 2)
        dl:AddCircleFilled(imgui.ImVec2(cx, pos.y + h / 2), h / 2 - 3, imgui.ImColor(255, 255, 255, 255):GetU32(), 24)
    end)
    if not ok then
        if imgui.Checkbox('##cb_' .. id, state) then changed = true end
    end
    imgui.SameLine(nil, 12)
    icon_text(icon_kind_for_label(label), label)
    return changed
end

local function menu_section(title)
    imgui.Spacing()
    local k = title == L.sec_orders and 'orders' or (title == L.sec_day and 'day' or (title == L.sec_session and 'session' or (title == L.sec_windows and 'windows' or 'total')))
    icon_text(k, title, ACCENT)
    imgui.Separator()
    imgui.Spacing()
end

local function rhAlpha(c, al)
    return (c % 16777216) + math.floor(al * 255 + 0.5) * 16777216
end

local function rhCardBox(drawList, x, y, w, h, bg, border, radius)
    drawList:AddRectFilled(imgui.ImVec2(x, y), imgui.ImVec2(x + w, y + h), bg, radius)
    drawList:AddLine(imgui.ImVec2(x + radius, y + 1), imgui.ImVec2(x + w - radius, y + 1), rhAlpha(0xFFFFFFFF, 0.05), 1.0)
    drawList:AddRect(imgui.ImVec2(x, y), imgui.ImVec2(x + w, y + h), border, radius, 15, 1.0)
end

local tab_highlight_y = nil
local tab_highlight_last = os.clock()
local menu_fade = 0
local menu_fade_last = os.clock()
local function menu_tab_button(label, idx)
    local selected = menu_tab == idx
    local dl = imgui.GetWindowDrawList()
    local base_pos = imgui.GetCursorScreenPos()
    local pos = base_pos
    local gutter = 9
    local w, h = math.max(20, imgui.GetContentRegionAvail().x - gutter), 38
    pos = imgui.ImVec2(pos.x + gutter, pos.y)
    imgui.SetCursorScreenPos(pos)
    if imgui.InvisibleButton('##tab_' .. idx, imgui.ImVec2(w, h)) then
        menu_tab = idx
    end
    local hovered = imgui.IsItemHovered()
    if selected then
        local t = os.clock()
        if not tab_highlight_y then tab_highlight_y = pos.y end
        local dt = math.max(0, math.min(t-tab_highlight_last, 0.1))
        tab_highlight_y = tab_highlight_y + (pos.y-tab_highlight_y)*math.min(1,dt*13)
        tab_highlight_last = t
        dl:AddRectFilled(imgui.ImVec2(pos.x - 7, tab_highlight_y + 4),
            imgui.ImVec2(pos.x - 4, tab_highlight_y + h - 4),0xFF1AE591,2)
    end
    local bgCol = selected and 0xFF1E3D1E or (hovered and 0xFF2A2A2A or 0xFF181818)
    local borderCol = selected and 0xFF1AE591 or (hovered and 0xFF555555 or 0xFF333333)
    local textCol = selected and 0xFF1AE591 or (hovered and 0xFFFFFFFF or 0xFFCCCCCC)
    rhCardBox(dl, pos.x, pos.y, w, h, bgCol, borderCol, 8)
    local textX = pos.x + 35
    local kind = idx == 1 and 'main' or (idx == 2 and 'settings' or 'history')
    local letter = idx == 1 and 'S' or (idx == 2 and 'G' or 'H')
    dl:AddRectFilled(imgui.ImVec2(pos.x + 10, pos.y + 11), imgui.ImVec2(pos.x + 29, pos.y + 29), 0xFF243D29, 4)
    fa_draw_at(kind, pos.x + 12, pos.y + 10, letter, textCol)
    local textH = imgui.CalcTextSize(label).y
    dl:AddText(imgui.ImVec2(textX, pos.y + (h - textH) / 2), textCol, label)
    imgui.SetCursorScreenPos(imgui.ImVec2(base_pos.x, pos.y + h + 4))
end

local function dashboard_card(label, value, sub, accent)
    imgui.BeginChild('##card_' .. label, imgui.ImVec2(0, 99), false, imgui.WindowFlags.NoScrollbar)
    icon_text('stats', label, MUTED)
    imgui.Spacing()
    imgui.PushFont(fontsizeBig)
    imgui.TextColored(accent or ACCENT, value)
    imgui.PopFont()
    if sub and sub ~= '' then imgui.TextColored(MUTED, sub) end
    imgui.EndChild()
end

local function logs_build()
    local list = {}
    local total_money, total_rides = 0, 0
    local cur = today()
    for d, r in pairs(history) do
        local rides = tonumber(r.rides) or 0
        local money = tonumber(r.money) or 0
        if rides > 0 or money > 0 then
            local y, m, dd = tostring(d):match('(%d+)-(%d+)-(%d+)')
            list[#list + 1] = {
                date  = d,
                label = y and (dd .. '.' .. m .. '.' .. y) or tostring(d),
                rides = rides,
                money = money,
                avg   = rides > 0 and money / rides or 0,
                today = d == cur
            }
            total_money = total_money + money
            total_rides = total_rides + rides
        end
    end
    table.sort(list, function(a, b) return a.date > b.date end)
    logs_cache = { list = list, money = total_money, rides = total_rides }
end

local function draw_overview()
    imgui.TextColored(MUTED, u8'КРАТКАЯ СВОДКА')
    imgui.Separator()
    imgui.Spacing()
    imgui.Columns(2, '##overview_columns', false)
    dashboard_card(
        u8'ЗАРАБОТАНО ЗА СЕССИЮ',
        '$' .. format_money(cfg.session.money),
        tostring(cfg.session.rides) .. u8' поездок'
    )
    imgui.NextColumn()
    dashboard_card(
        u8'ЗАРАБОТАНО СЕГОДНЯ',
        '$' .. format_money(cfg.day.money),
        tostring(cfg.day.rides) .. u8' поездок',
        imgui.ImVec4(0.35, 0.85, 1.0, 1.0)
    )
    imgui.NextColumn()
    local sr = tonumber(cfg.session.rides) or 0
    local sm = tonumber(cfg.session.money) or 0
    dashboard_card(
        u8'СРЕДНИЙ ЧЕК СЕССИИ',
        '$' .. format_money(sr > 0 and sm / sr or 0),
        u8'За текущую сессию'
    )
    imgui.NextColumn()
    dashboard_card(
        u8'РАБОЧЕЕ ВРЕМЯ СЕГОДНЯ',
        format_time(tonumber(cfg.day.worked) or 0),
        tostring(cfg.day.boxes or 0) .. u8' ларцов получено',
        imgui.ImVec4(0.35, 0.85, 1.0, 1.0)
    )
    imgui.Columns(1)
    imgui.Spacing()
    imgui.Separator()
    imgui.TextColored(ACCENT, u8'РАСШИРЕННАЯ СТАТИСТИКА')
    local seven_money, seven_rides, seven_worked = 0, 0, 0
    local yesterday = TaxiHelperUi.dayKey(1)
    local yesterday_money = tonumber(history[yesterday] and history[yesterday].money) or 0
    for i=0,6 do
        local date = TaxiHelperUi.dayKey(i)
        local r = history[date]
        if r then
            seven_money=seven_money+(tonumber(r.money) or 0)
            seven_rides=seven_rides+(tonumber(r.rides) or 0)
            seven_worked=seven_worked+(tonumber(r.worked) or 0)
        end
    end
    imgui.Text(u8'Заработок за 7 дней: $' .. format_money(seven_money))
    imgui.Text(u8'Поездок за 7 дней: ' .. tostring(seven_rides))
    imgui.Text(u8'Доход в час (7 дней): $' .. format_money(seven_worked > 0 and seven_money * 3600 / seven_worked or 0))
    imgui.Text(u8'Самая прибыльная поездка сессии: $' .. format_money(cfg.session.best_ride))
    imgui.Text(u8'Вчера: $' .. format_money(yesterday_money))
    local delta = (tonumber(cfg.day.money) or 0) - yesterday_money
    imgui.TextColored(delta >= 0 and ACCENT or MUTED,
        u8'Сегодня относительно вчера: ' .. (delta >= 0 and '+' or '-') .. '$' .. format_money(math.abs(delta)))
end

function TaxiHelperUi.dayKey(offset)
    local t = os.date('*t')
    return os.date('%Y-%m-%d', os.time({ year = t.year, month = t.month, day = t.day - offset, hour = 12 }))
end

function TaxiHelperUi.actionButton(label, width, height, selected, marked)
    local base = selected and imgui.ImVec4(0.12, 0.30, 0.17, 0.96)
        or (marked and imgui.ImVec4(0.11, 0.23, 0.15, 0.96)
            or imgui.ImVec4(0.12, 0.14, 0.16, 0.98))
    imgui.PushStyleColor(imgui.Col.Button, base)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.18, 0.34, 0.22, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.20, 0.42, 0.24, 1.0))
    imgui.PushStyleColor(imgui.Col.Text,
        selected and imgui.ImVec4(0.48, 1.0, 0.56, 1.0)
            or imgui.ImVec4(0.91, 0.95, 0.93, 1.0))
    imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 6)
    local pressed = imgui.Button(label, imgui.ImVec2(width, height))
    imgui.PopStyleVar()
    imgui.PopStyleColor(4)
    return pressed
end

function TaxiHelperUi.numericControl(key, input_buffer, label_id, min_value, max_value, step, width)
    local was_active = TaxiHelperUi.numericEditActive[key]
    imgui.PushItemWidth(width)
    local changed = imgui.InputText(label_id, input_buffer)
    local active_now = imgui.IsItemActive()
    imgui.PopItemWidth()
    if changed then
        local entered = math.floor(TaxiHelperUi.parseNumber(input_buffer.v))
        entered = math.max(min_value, math.min(max_value, entered))
        cfg.ui[key] = entered
        uib[key].v = entered
        TaxiHelperUi.numericDirty[key] = true
    end
    if was_active and not active_now and not changed then
        if TaxiHelperUi.numericDirty[key] then
            save()
            TaxiHelperUi.numericDirty[key] = false
        end
        input_buffer.v = format_money(cfg.ui[key] or min_value)
    end
    TaxiHelperUi.numericEditActive[key] = active_now
    imgui.SameLine(nil, 6)
    if TaxiHelperUi.actionButton('-##th_minus_' .. key, 30, 28) then
        local new_amount = math.max(min_value, (tonumber(cfg.ui[key]) or min_value) - step)
        cfg.ui[key] = new_amount
        uib[key].v = new_amount
        input_buffer.v = format_money(new_amount)
        TaxiHelperUi.numericDirty[key] = false
        save()
    end
    imgui.SameLine(nil, 5)
    if TaxiHelperUi.actionButton('+##th_plus_' .. key, 30, 28) then
        local new_amount = math.min(max_value, (tonumber(cfg.ui[key]) or min_value) + step)
        cfg.ui[key] = new_amount
        uib[key].v = new_amount
        input_buffer.v = format_money(new_amount)
        TaxiHelperUi.numericDirty[key] = false
        save()
    end
end

function TaxiHelperUi.applyGoalAmount(amount)
    amount = math.max(0, math.min(2000000000, math.floor(tonumber(amount) or 0)))
    cfg.ui.goal_amount = amount
    uib.goal_amount.v = amount
    save()
end

local function draw_goal_editor()
    local value = math.max(0, math.floor(tonumber(cfg.ui.goal_amount) or 0))
    if TaxiHelperUi.actionButton(format_money(value) .. '##th_goal_open', 150, 28) then
        goal_keyboard_digits = tostring(value)
        goal_keyboard_replace = true
        goal_keyboard_save = false
        goal_keyboard_cancel = false
        goal_keyboard_editor = true
    end
    imgui.SameLine(nil, 6)
    if TaxiHelperUi.actionButton('-##th_goal_decrease', 30, 28) then
        TaxiHelperUi.applyGoalAmount(value - 1000000)
    end
    imgui.SameLine(nil, 5)
    if TaxiHelperUi.actionButton('+##th_goal_increase', 30, 28) then
        TaxiHelperUi.applyGoalAmount(value + 1000000)
    end
end

local function draw_goal_edit_dialog()
    if not goal_keyboard_editor or not menu_open.v then return end
    if goal_keyboard_cancel then
        goal_keyboard_editor = false
        goal_keyboard_cancel = false
        return
    end
    if goal_keyboard_save then
        TaxiHelperUi.applyGoalAmount(TaxiHelperUi.parseNumber(goal_keyboard_digits))
        goal_keyboard_editor = false
        goal_keyboard_save = false
        return
    end
    local io = imgui.GetIO()
    imgui.SetNextWindowSize(imgui.ImVec2(425, 199), imgui.Cond.Always)
    imgui.SetNextWindowPos(imgui.ImVec2(io.DisplaySize.x / 2, io.DisplaySize.y / 2),
        imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 9)
    imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(17, 14))
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.075, 0.085, 0.09, 0.99))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.20, 0.56, 0.29, 0.85))
    imgui.Begin(u8'##TaxiHelperGoalEdit', nil,
        imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoMove)
    imgui.TextColored(ACCENT, u8'ИЗМЕНЕНИЕ ДНЕВНОЙ ЦЕЛИ')
    imgui.Separator()
    imgui.TextColored(MUTED, u8'Начните вводить новую сумму цифрами.')
    local amount = math.min(2000000000, TaxiHelperUi.parseNumber(goal_keyboard_digits))
    local blink = (math.floor(os.clock() * 2) % 2 == 0) and '|' or ' '
    local display = (goal_keyboard_digits == '' and '0' or format_money(amount)) .. blink
    imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0.13, 0.16, 0.16, 1.0))
    imgui.BeginChild('##th_goal_keyboard_display', imgui.ImVec2(-1, 38), true, imgui.WindowFlags.NoScrollbar)
    imgui.TextColored(imgui.ImVec4(0.80, 1.0, 0.85, 1.0), display)
    imgui.EndChild()
    imgui.PopStyleColor()
    imgui.TextColored(MUTED, u8'Сумма после сохранения: $' .. format_money(amount))
    imgui.Spacing()
    if TaxiHelperUi.actionButton(u8'Сохранить##th_goal_save', 178, 31, true) then
        goal_keyboard_save = true
    end
    imgui.SameLine(nil, 9)
    if TaxiHelperUi.actionButton(u8'Отмена##th_goal_cancel', 178, 31) then
        goal_keyboard_cancel = true
    end
    imgui.End()
    imgui.PopStyleColor(2)
    imgui.PopStyleVar(2)
end

local function draw_settings()
    imgui.BeginChild('##settings', imgui.ImVec2(0, 0), false)
    menu_section(L.sec_windows)
    if ui_toggle('stats', L.opt_stats, show) then save() end
    if ui_toggle('notify', L.opt_notify, uib.notify) then ui_commit('notify') end
    imgui.Spacing()
    if TaxiHelperUi.actionButton(L.btn_move .. '##th_move', 280, 32) then
        edit_mode = true
        show.v = true
        menu_open.v = false
    end
    menu_section(L.sec_keys)
    icon_text('settings', L.menu_key, MUTED)
    imgui.SameLine(200)
    local key_label = menu_key_capture and L.key_press
        or (L.key_bind .. ': ' .. ((menu_key > 0) and key_vk_name(menu_key) or L.key_none))
    if TaxiHelperUi.actionButton(key_label .. '##th_menu_key', 230, 28, menu_key_capture) then
        menu_key_capture = not menu_key_capture
        menu_key_held = false
    end
    imgui.SameLine(nil, 6)
    if TaxiHelperUi.actionButton(L.key_off .. '##th_menu_key_off', 90, 28) then
        menu_key = 0
        menu_key_held = false
        menu_key_capture = false
        menu_key_changed = true
    end
    if menu_key_capture then
        imgui.TextColored(MUTED, L.key_hint)
    else
        imgui.TextColored(MUTED, L.key_note)
    end
    imgui.Spacing()
    menu_section(L.sec_meter)
    if ui_toggle('meter_show', L.meter_show, meter_show) then
        cfg.meter.show = meter_show.v
        save()
    end
    if ui_toggle('meter_auto', L.meter_auto, uib.meter_auto) then ui_commit('meter_auto') end
    icon_text('earned', L.meter_coeff, MUTED)
    imgui.SameLine(200)
    imgui.PushItemWidth(150)
if imgui.InputText('##th_meter_coeff', TaxiHelperUi.meterInput) then
        local meter_str = (TaxiHelperUi.meterInput.v or ''):gsub(',', '.')
        local v = tonumber(meter_str)
        if v and v >= METER_MIN_COEFF and v <= METER_MAX_COEFF then
            cfg.ui.meter_coeff = v
            if uib.meter_auto.v then
                uib.meter_auto.v = false
                cfg.ui.meter_auto = 0
            end
            TaxiHelperUi.meterDirty = true
        end
    end
    imgui.PopItemWidth()
    if TaxiHelperUi.meterDirty and not imgui.IsItemActive() then
        TaxiHelperUi.meterDirty = false
        save()
    end
    imgui.Spacing()
    local meter_rec = (meter.car ~= '') and meter_data[meter.car] or nil
    local meter_car_txt = meter_car_display(meter.car)
    if meter_rec then
        imgui.TextColored(MUTED, u8('Машина: ') .. meter_car_txt .. u8('  -  x') .. meter_coeff_str(meter_rec.k)
            .. '  (' .. tostring(meter_rec.n) .. u8(' рейс.)'))
    else
        local prefix = (meter_car_txt ~= '') and (u8('Машина: ') .. meter_car_txt .. u8('  -  ')) or ''
        imgui.TextColored(MUTED, prefix .. L.meter_need)
    end
    imgui.Spacing()
    if TaxiHelperUi.actionButton(L.meter_reset .. '##th_meter_reset', 220, 28) then
        if meter.car ~= '' then
            meter_data[meter.car] = nil
            meter_save()
        end
        cfg.ui.meter_coeff = 0
        meter_sync_input()
        save()
    end
    imgui.Spacing()
    if TaxiHelperUi.actionButton(L.meter_move .. '##th_meter_move', 260, 30) then
        meter_edit = true
        meter_show.v = true
        cfg.meter.show = true
        menu_open.v = false
    end
    menu_section(L.sec_goal)
    imgui.Text(L.goal_amount)
    imgui.SameLine(200)
    draw_goal_editor()
    imgui.TextColored(MUTED, L.goal_off)
    menu_section(L.sec_session)
    for _, it in ipairs(SESSION_ITEMS) do
        if ui_toggle(it.key, it.label, uib[it.key]) then ui_commit(it.key) end
    end
    menu_section(L.sec_day)
    for _, it in ipairs(DAY_ITEMS) do
        if ui_toggle(it.key, it.label, uib[it.key]) then ui_commit(it.key) end
    end
    menu_section(L.sec_orders)
    if ui_toggle('auto_catch', L.auto_catch, uib.auto_catch) then
        ui_commit('auto_catch')
        if uib.auto_catch.v then
            order_collect_start, order_collect_until = 0, 0
            pickBest()
        end
    end
    if ui_toggle('bot_only', L.bot_only, uib.bot_only) then
        ui_commit('bot_only')
        if not busy and not catching then pickBest() end
    end
    imgui.Spacing()
    icon_text('orders', L.catch_mode)
    local instant = uib.catch_mode.v == 1
    if TaxiHelperUi.actionButton(L.mode_instant .. '##th_catch_instant', 145, 30, instant) then
        uib.catch_mode.v = 1
        cfg.ui.catch_mode = 1
        order_collect_start, order_collect_until = 0, 0
        save()
        pickBest()
    end
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8'Сразу принимает первый подходящий заказ без задержки.')
        imgui.EndTooltip()
    end
    imgui.SameLine(nil, 8)
    if TaxiHelperUi.actionButton(L.mode_nearest .. '##th_catch_nearest', 177, 30, not instant) then
        uib.catch_mode.v = 2
        cfg.ui.catch_mode = 2
        order_collect_start, order_collect_until = 0, 0
        save()
        pickBest()
    end
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8'Ждёт 50 мс и выбирает ближайший заказ.')
        imgui.EndTooltip()
    end
    imgui.Spacing()
    icon_text('distance', L.order_dist)
    imgui.SameLine(200)
    TaxiHelperUi.numericControl('max_distance', TaxiHelperUi.distanceInput, '##th_max_dist', 100, 20000, 100, 150)
    imgui.Spacing()
    if ui_toggle('sound_on', L.sound_on, uib.sound_on) then ui_commit('sound_on') end
    if uib.sound_on.v then
        imgui.Spacing()
        icon_text('notify', L.sound_kind)
        for kind = 1, 6 do
            local selected = uib.sound_kind.v == kind
            if TaxiHelperUi.actionButton(L['snd_' .. kind] .. '##th_snd_kind_' .. kind, 150, 30, selected) then
                uib.sound_kind.v = kind
                cfg.ui.sound_kind = kind
                save()
                if kind == 6 then TaxiHelperSound.ensure_yandex() end
                TaxiHelperSound.play_selected()
            end
            if kind == 5 and imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text(u8'Положи файл custom.mp3 (или .wav / .ogg) в moonloader\\resource\\TaxiHelper')
                imgui.EndTooltip()
            end
            if kind == 6 and imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text(u8'Скачивается автоматически при запуске. Файл: moonloader\\resource\\TaxiHelper\\yandex.mp3')
                imgui.EndTooltip()
            end
            if kind == 1 or kind == 2 or kind == 4 or kind == 5 then imgui.SameLine(nil, 8) end
        end
        imgui.Spacing()
        icon_text('notify', L.sound_volume)
        imgui.SameLine(200)
        imgui.PushItemWidth(190)
        if imgui.SliderInt('##th_snd_volume', uib.sound_volume, 0, 100) then
            cfg.ui.sound_volume = uib.sound_volume.v
            TaxiHelperUi.soundDirty = true
        end
        imgui.PopItemWidth()
        if TaxiHelperUi.soundDirty and not imgui.IsMouseDown(0) then
            TaxiHelperUi.soundDirty = false
            save()
        end
        imgui.SameLine(nil, 8)
        if TaxiHelperUi.actionButton(L.sound_test .. '##th_snd_test', 150, 28) then
            TaxiHelperSound.play_selected()
        end
    end
    imgui.EndChild()
end

local function meter_draw()
    if not meter_show.v then return end
    local visible = meter_edit or (meter.active and meter.type == 'taxi')
        or (meter.last_end > 0 and (game_ms() - meter.last_end) < METER_DRAW_LINGER)
    if not visible then return end
    local base = meter.active and meter.base or meter.last_base
    local k = meter_active_coeff()
    local income = (k > 0) and math.floor(base * k + 0.5) or nil
    local elapsed = 0
    if meter.active and meter.started > 0 then
        elapsed = math.max(0, math.floor((game_ms() - meter.started) / 1000))
    end
    local flags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize
        + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoSavedSettings
    if not meter_edit then
        flags = flags + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoInputs
    end
    imgui.SetNextWindowPos(imgui.ImVec2(tonumber(cfg.meter.x) or 100, tonumber(cfg.meter.y) or 430), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(300, meter_edit and 172 or 124), imgui.Cond.Always)
    imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 10)
    imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(13, 10))
    imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 3))
    imgui.PushStyleColor(imgui.Col.WindowBg, WINDOW_BG)
    imgui.PushStyleColor(imgui.Col.Border, WINDOW_BORDER)
    imgui.Begin(u8'##TaxiMeter', meter_show, flags)
    imgui.PushFont(fontsize)
    imgui.TextColored(TAXI_YELLOW, L.meter_title)
    local k_str = (k > 0) and ('x' .. meter_coeff_str(k)) or 'x --'
    imgui.SameLine(imgui.GetWindowWidth() - imgui.CalcTextSize(k_str).x - 13)
    imgui.TextColored(k > 0 and ACCENT or MUTED, k_str)
    imgui.Separator()
    icon_text('earned', L.meter_base)
    imgui.SameLine(132)
    draw_money(base)
    icon_text('earned', L.meter_income)
    imgui.SameLine(132)
    if income then
        imgui.TextColored(ACCENT, '$ ' .. format_money(income))
    else
        imgui.TextDisabled('--')
    end
    if meter.active then
        local extra = ''
        if elapsed >= 15 and income and income > 0 then
            extra = '   ~' .. meter_short_money(income * 3600 / elapsed) .. u8'/ч'
        end
        icon_text('time', L.meter_time)
        imgui.SameLine(132)
        imgui.Text(format_time(elapsed) .. extra)
    elseif meter.paid > 0 and (game_ms() - meter.paid_ms) < METER_DRAW_LINGER then
        icon_text('earned', L.meter_paid)
        imgui.SameLine(132)
        imgui.TextColored(DOLLAR_COLOR, '$ ' .. format_money(meter.paid))
    end
    imgui.PopFont()
    if meter_edit then
        if imgui.Button('[+] ' .. L.save_pos, imgui.ImVec2(-1, 26)) then
            local pos = imgui.GetWindowPos()
            cfg.meter.x = math.floor(pos.x)
            cfg.meter.y = math.floor(pos.y)
            save()
            meter_edit = false
            imgui.ShowCursor = false
        end
    end
    imgui.End()
    imgui.PopStyleColor(2)
    imgui.PopStyleVar(3)
end

local calendar_month = os.date('*t').month
local calendar_year = os.date('*t').year
local calendar_selected = nil
local function calendar_month_shift(delta)
    local n = calendar_year * 12 + calendar_month - 1 + delta
    calendar_year = math.floor(n / 12)
    calendar_month = n % 12 + 1
end
local function draw_calendar()
    imgui.TextColored(ACCENT, u8'КАЛЕНДАРЬ ЗАРАБОТКА')
    if TaxiHelperUi.actionButton('<##prev_month', 30, 26) then calendar_month_shift(-1) end
    imgui.SameLine()
    imgui.Text(string.format('%02d.%04d', calendar_month, calendar_year))
    imgui.SameLine()
    if TaxiHelperUi.actionButton('>##next_month', 30, 26) then calendar_month_shift(1) end
    imgui.SameLine()
    if TaxiHelperUi.actionButton(u8'Сегодня##cal_today', 86, 26) then
        local t = os.date('*t'); calendar_month=t.month; calendar_year=t.year
        calendar_selected = today()
    end
    local first = os.time({year=calendar_year,month=calendar_month,day=1,hour=12})
    local weekday = (tonumber(os.date('%w', first)) + 6) % 7
    local next_month = os.time({year=calendar_year,month=calendar_month+1,day=1,hour=12})
    local days = math.floor((next_month-first)/86400 + 0.5)
    local weekdays = {'Пн','Вт','Ср','Чт','Пт','Сб','Вс'}
    for i=1,7 do
        if i>1 then imgui.SameLine(nil, 5) end
        imgui.TextColored(MUTED, u8(weekdays[i] .. '   '))
    end
    for blank=1,weekday do
        if blank>1 then imgui.SameLine(nil, 5) end
        imgui.Dummy(imgui.ImVec2(38, 23))
    end
    for day=1,days do
        local cell = weekday + day - 1
        if cell % 7 ~= 0 then imgui.SameLine(nil, 5) end
        local date = string.format('%04d-%02d-%02d', calendar_year,calendar_month,day)
        local entry = history[date]
        local label = string.format('%02d',day) .. '##cal_' .. date
        local has_money = entry and (tonumber(entry.money) or 0) > 0
        if TaxiHelperUi.actionButton(label, 38, 25, calendar_selected == date, has_money) then
            calendar_selected = date
        end
    end
    if calendar_selected then
        local r = history[calendar_selected]
        imgui.Separator()
        imgui.Text(calendar_selected)
        if r then
            imgui.Text(u8'Поездок: ' .. tostring(r.rides or 0))
            imgui.SameLine(170); imgui.Text(u8'Заработано: $' .. format_money(r.money))
            imgui.Text(u8'Отработано: ' .. format_time(r.worked))
            imgui.SameLine(170); imgui.Text(u8'Чаевые: ' .. tostring(r.tips or 0))
            imgui.Text(u8('Ларцы: ' .. tostring(r.boxes or 0) .. '  |  Монеты: ' .. tostring(r.coins or 0)))
        else
            imgui.TextDisabled(u8'За выбранный день записей нет')
        end
    end
    imgui.Separator()
end

local history_view = 1
local function draw_logs()
    if TaxiHelperUi.actionButton(u8'История по дням##hist_days', 170, 30, history_view == 1) then history_view=1 end
    imgui.SameLine(nil, 7)
    if TaxiHelperUi.actionButton(u8'Календарь##hist_calendar', 126, 30, history_view == 2) then history_view=2 end
    imgui.Separator()
    if history_view == 2 then
        draw_calendar()
        return
    end
    if not logs_cache or logs_cache_rev ~= history_rev then
        logs_build()
        logs_cache_rev = history_rev
    end
    local c = logs_cache
    menu_section(L.sec_total)
    imgui.PushFont(fontsizeBig)
    imgui.TextColored(DOLLAR_COLOR, '$')
    imgui.SameLine(nil, 4)
    imgui.Text(format_money(c.money))
    imgui.PopFont()
    local avg = c.rides > 0 and c.money / c.rides or 0
    imgui.TextColored(MUTED, string.format(L.total_fmt, c.rides, #c.list, format_money(avg)))
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()
    icon_text('date', L.col_date, MUTED)
    imgui.SameLine(200)
    icon_text('rides', L.col_rides, MUTED)
    imgui.SameLine(300)
    icon_text('earned', L.col_money, MUTED)
    imgui.SameLine(450)
    icon_text('avg', L.col_avg, MUTED)
    imgui.BeginChild('##loglist', imgui.ImVec2(0, 0), true)
    if #c.list == 0 then
        imgui.TextDisabled(L.no_data)
    end
    for _, r in ipairs(c.list) do
        imgui.Text(r.label)
        if r.today then
            imgui.SameLine(nil, 8)
            imgui.TextColored(ACCENT, L.today)
        end
        imgui.SameLine(200)
        imgui.Text(tostring(r.rides))
        imgui.SameLine(300)
        draw_money(r.money)
        imgui.SameLine(450)
        draw_money(r.avg)
    end
    imgui.EndChild()
end

local function draw_menu()
    local io = imgui.GetIO()
    imgui.SetNextWindowSize(imgui.ImVec2(960, 580), imgui.Cond.Always)
    imgui.SetNextWindowPos(imgui.ImVec2(io.DisplaySize.x / 2, io.DisplaySize.y / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 3)
    imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 3)
    imgui.PushStyleVar(imgui.StyleVar.ChildWindowRounding, 3)
    imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(14, 14))
    imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(9, 8))
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.075, 0.078, 0.085, 0.90))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.20, 0.21, 0.22, 1.0))
    imgui.Begin(u8'##TaxiHelper', menu_open, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
    local winPos = imgui.GetWindowPos()
    local winSize = imgui.GetWindowSize()
    local titleBarHeight = 24
    local in_strip = imgui.IsMouseHoveringRect(winPos, imgui.ImVec2(winPos.x + winSize.x, winPos.y + titleBarHeight), false)
        and not imgui.IsMouseHoveringRect(imgui.ImVec2(winPos.x + winSize.x - 280, winPos.y + 12), imgui.ImVec2(winPos.x + winSize.x, winPos.y + 60), false)
    if imgui.IsMouseDown(0) then
        local mousePos = imgui.GetMousePos()
        if not dragStartPos and in_strip and imgui.IsMouseClicked(0) then
            dragStartPos = { x = mousePos.x - winPos.x, y = mousePos.y - winPos.y }
        end
        if dragStartPos then
            imgui.SetWindowPos(imgui.ImVec2(mousePos.x - dragStartPos.x, mousePos.y - dragStartPos.y))
        end
    else
        dragStartPos = nil
    end
    imgui.PushFont(fontsize)
    imgui.BeginChild('##sidebar', imgui.ImVec2(174, 0), true, imgui.WindowFlags.NoScrollbar)
    imgui.Spacing()
    imgui.TextColored(ACCENT, u8'TAXI')
    imgui.SameLine(nil, 5)
    imgui.Text(u8'HELPER')
    imgui.TextColored(MUTED, u8'DRIVER DASHBOARD')
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()
    menu_tab_button(u8'Главная', 1)
    menu_tab_button(u8'Настройки', 2)
    menu_tab_button(u8'История', 3)
    imgui.Spacing()
    imgui.Separator()
    imgui.TextColored(MUTED, u8'ТЕКУЩАЯ СЕССИЯ')
    imgui.TextColored(ACCENT, '$' .. format_money(cfg.session.money))
    imgui.TextColored(MUTED, tostring(cfg.session.rides) .. u8' поездок')
    imgui.Spacing()
    imgui.TextColored(MUTED, u8'СЕГОДНЯ')
    imgui.TextColored(imgui.ImVec4(0.35, 0.85, 1.0, 1.0), '$' .. format_money(cfg.day.money))
    imgui.TextColored(MUTED, tostring(cfg.day.rides) .. u8' поездок')
    imgui.SetCursorPosY(math.max(imgui.GetCursorPosY(), imgui.GetWindowHeight() - 43))
    imgui.Separator()
    imgui.TextColored(MUTED, u8'ESC  -  Закрыть меню')
    imgui.EndChild()
    imgui.SameLine()
    imgui.BeginChild('##maincontent', imgui.ImVec2(0, 0), false, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
    update_draw_button()
    if menu_tab == 1 then
        draw_overview()
    else
        imgui.Separator()
        imgui.Spacing()
        if menu_tab == 2 then
            draw_settings()
        else
            draw_logs()
        end
    end
    imgui.EndChild()
    imgui.PopFont()
    imgui.End()
    imgui.PopStyleColor(2)
    imgui.PopStyleVar(5)
end

function imgui.OnDrawFrame()
    imgui.ShowCursor = edit_mode or menu_open.v or meter_edit
    imgui.LockPlayer = menu_open.v or meter_edit

    if show.v then
        local flags = imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize
        if not edit_mode then
            flags = flags + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoInputs
        end
        imgui.SetNextWindowPos(
            imgui.ImVec2(tonumber(cfg.window.x) or 100, tonumber(cfg.window.y) or 100),
            imgui.Cond.FirstUseEver
        )
        imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 10)
        imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(14, 12))
        imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 2))
        imgui.PushStyleColor(imgui.Col.WindowBg, WINDOW_BG)
        imgui.PushStyleColor(imgui.Col.Border, WINDOW_BORDER)
        imgui.Begin(L.window, show, flags)
        if edit_mode then
            imgui.PushFont(fontsize)
            imgui.TextColored(imgui.ImVec4(0.26, 0.98, 0.26, 1.0), L.move_mode)
            if imgui.Button('[+] ' .. L.save_pos, imgui.ImVec2(-1, 28)) then
                local pos = imgui.GetWindowPos()
                cfg.window.x = math.floor(pos.x)
                cfg.window.y = math.floor(pos.y)
                cfg.window.show = show.v
                inicfg.save(cfg, config_path)
                edit_mode = false
                imgui.ShowCursor = false
            end
            colored_separator(66, 220, 82)
            imgui.PopFont()
        end
        imgui.PushFont(fontsizeBig)
        local win_w = imgui.GetWindowWidth()
        local text_taxi = u8'TAXI'
        local text_helper = u8' HELPER'
        local w_taxi = imgui.CalcTextSize(text_taxi).x
        local w_helper = imgui.CalcTextSize(text_helper).x
        imgui.SetCursorPosX((win_w - (w_taxi + w_helper)) / 2)
        imgui.TextColored(TAXI_YELLOW, text_taxi)
        imgui.SameLine(nil, 0)
        imgui.TextColored(TAXI_WHITE, text_helper)
        imgui.PopFont()
        local any_s = uib.s_rides.v or uib.s_money.v or uib.s_avg.v or uib.s_time.v
        if any_s then
            imgui.PushFont(fontsize)
            if uib.s_rides.v then
                icon_text('rides', L.rides)
                imgui.SameLine(COL_X)
                imgui.Text(tostring(cfg.session.rides))
            end
            if uib.s_money.v then
                icon_text('earned', L.earned)
                imgui.SameLine(COL_X)
                draw_money(cfg.session.money)
            end
            if uib.s_avg.v then
                icon_text('avg', L.avg)
                imgui.SameLine(COL_X)
                local sr = tonumber(cfg.session.rides) or 0
                if sr > 0 then
                    draw_money((tonumber(cfg.session.money) or 0) / sr)
                else
                    imgui.TextDisabled(L.dash)
                end
            end
            if uib.s_time.v then
                icon_text('time', L.session_time)
                imgui.SameLine(COL_X)
                if session_start > 0 then
                    imgui.Text(format_time(now() - session_start))
                elseif session_elapsed > 0 then
                    imgui.TextDisabled(format_time(session_elapsed))
                else
                    imgui.TextDisabled(L.long_dash)
                end
            end
            imgui.PopFont()
            colored_separator(SEP_SESSION[1], SEP_SESSION[2], SEP_SESSION[3])
        end
        local any_d = uib.d_money.v or uib.d_worked.v or uib.d_rides.v or uib.d_boxes.v
            or uib.d_coins.v or uib.d_tips.v or uib.d_avg.v
        if any_d then
            imgui.PushFont(fontsizeBig)
            colored_centered_header(L.day_header, HEADER_DAY_COLOR)
            imgui.PopFont()
            imgui.Dummy(imgui.ImVec2(0, 5))
            imgui.PushFont(fontsize)
            if uib.d_money.v then
                icon_text('earned', L.earned)
                imgui.SameLine(COL_X)
                draw_money(cfg.day.money)
            end
            if uib.d_avg.v then
                icon_text('avg', L.avg)
                imgui.SameLine(COL_X)
                local dr = tonumber(cfg.day.rides) or 0
                if dr > 0 then
                    draw_money((tonumber(cfg.day.money) or 0) / dr)
                else
                    imgui.TextDisabled(L.dash)
                end
            end
            if uib.d_rides.v then
                icon_text('rides', L.rides)
                imgui.SameLine(COL_X)
                imgui.Text(tostring(cfg.day.rides))
            end
            if uib.d_worked.v then
                icon_text('worked', L.worked)
                imgui.SameLine(COL_X)
                local worked = tonumber(cfg.day.worked) or 0
                if session_start > 0 then
                    worked = worked + (now() - session_start)
                end
                if worked > 0 then
                    imgui.Text(format_time(worked))
                else
                    imgui.TextDisabled(L.long_dash)
                end
            end
            if uib.d_boxes.v then
                icon_text('boxes', L.i_boxes .. ':')
                imgui.SameLine(COL_X)
                imgui.Text(format_money(cfg.day.boxes))
            end
            if uib.d_coins.v then
                icon_text('coins', L.i_coins .. ':')
                imgui.SameLine(COL_X)
                imgui.Text(format_money(cfg.day.coins))
            end
            if uib.d_tips.v then
                icon_text('tips', L.i_tips .. ':')
                imgui.SameLine(COL_X)
                if tonumber(cfg.day.tips_cash) == 1 then
                    draw_money(cfg.day.tips)
                else
                    imgui.Text(format_money(cfg.day.tips))
                end
            end
            imgui.PopFont()
            colored_separator(SEP_DAY[1], SEP_DAY[2], SEP_DAY[3])
        end
        imgui.End()
        imgui.PopStyleColor(2)
        imgui.PopStyleVar(3)
    end

    meter_draw()

    local alpha = notification_alpha()
    if alpha > 0 then
        local io = imgui.GetIO()
        local elapsed = game_ms() - notification.started
        notification_icon_alpha = alpha
        local flagsNotify = imgui.WindowFlags.NoTitleBar
            + imgui.WindowFlags.NoResize
            + imgui.WindowFlags.NoMove
            + imgui.WindowFlags.NoSavedSettings
            + imgui.WindowFlags.NoInputs

        local goal_enabled = (tonumber(cfg.ui.goal_amount) or 0) > 0
        local meter_line = ((notification.meter_k or 0) > 0 and (notification.meter_base or 0) > 0)
        imgui.SetNextWindowSize(imgui.ImVec2(395, (goal_enabled and 251 or 174) + (meter_line and 26 or 0)), imgui.Cond.Always)
        imgui.SetNextWindowPos(
            imgui.ImVec2(io.DisplaySize.x * 0.5, io.DisplaySize.y * 0.12 + (1.0 - alpha) * 12),
            imgui.Cond.Always,
            imgui.ImVec2(0.5, 0.0)
        )
        imgui.PushStyleVar(imgui.StyleVar.Alpha, alpha)
        imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 11)
        imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(16, 12))
        imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(7, 5))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.04, 0.05, 0.07, 0.85))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(1.0, 0.85, 0.2, 0.8))
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
        notification_show.v = true
        imgui.Begin(L.notify_id, notification_show, flagsNotify)
        imgui.PushFont(fontsizeNotifyBig)
        local title = L.ride_done
        local title_w = imgui.CalcTextSize(title).x
        imgui.SetCursorPosX((imgui.GetWindowWidth() - title_w) / 2)
        local pulse = (0.9 + 0.1 * math.sin(elapsed / 260))
        icon_text('rides', title, imgui.ImVec4(1.0, 0.85, 0.15, pulse))
        imgui.PopFont()
        imgui.Spacing()
        imgui.PushFont(fontsizeNotify)
        local count_duration = 700
        local count_progress = math.min(elapsed / count_duration, 1.0)
        local count_ease = count_progress * count_progress * (3 - 2 * count_progress)
        local display_money = notification.ride_money * count_ease
        local plus = L.plus .. format_money(display_money)
        local plus_w = imgui.CalcTextSize(plus).x
        imgui.SetCursorPosX((imgui.GetWindowWidth() - plus_w) / 2)
        imgui.TextColored(imgui.ImVec4(0.35, 1.0, 0.35, 1.0), plus)
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        local amount_x = 233
        icon_text('earned', L.session_sum)
        imgui.SameLine(amount_x)
        imgui.TextColored(imgui.ImVec4(0.35, 1.0, 0.35, 1.0), '$ ' .. format_money(notification.session_money))
        icon_text('day', L.day_sum)
        imgui.SameLine(amount_x)
        imgui.TextColored(imgui.ImVec4(0.35, 1.0, 0.35, 1.0), '$ ' .. format_money(notification.day_money))
        if meter_line then
            imgui.Spacing()
            local meter_text = L.meter_title .. '  x' .. meter_coeff_str(notification.meter_k)
                .. '  =  $ ' .. format_money(notification.meter_income)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(meter_text).x) / 2)
            imgui.TextColored(MUTED, meter_text)
        end
        imgui.PopFont()
        local goal_amount = math.max(0, tonumber(cfg.ui.goal_amount) or 0)
        if goal_amount > 0 then
            local earned = math.max(0, tonumber(notification.day_money) or 0)
            local previous_earned = math.max(0, earned - (tonumber(notification.ride_money) or 0))
            local start_ratio = previous_earned / goal_amount
            local end_ratio = earned / goal_amount
            local anim_t = math.max(0, math.min(elapsed / 1450, 1))
            local eased = anim_t * anim_t * (3 - 2 * anim_t)
            local animated_ratio = start_ratio + (end_ratio - start_ratio) * eased
            local pct = math.max(0, math.floor(animated_ratio * 100 + 0.5))
            local fill_ratio = math.max(0, math.min(animated_ratio, 1))
            local remaining = math.max(0, goal_amount - earned)
            imgui.Spacing()
            local p = imgui.GetCursorScreenPos()
            local w = imgui.GetContentRegionAvail().x
            local h = 73
            local dl = imgui.GetWindowDrawList()
            dl:AddRectFilled(imgui.ImVec2(p.x, p.y),
                imgui.ImVec2(p.x + w, p.y + h), fade_draw_color(0xB51A2320), 7)
            local title2 = remaining == 0 and u8'Цель достигнута!' or (u8'До цели: $' .. format_money(remaining))
            local pct_text = tostring(pct) .. '%'
            dl:AddText(imgui.ImVec2(p.x + 12, p.y + 9),
                fade_draw_color(remaining == 0 and 0xFF71F18D or 0xFFCED9D1), title2)
            local pct_w = imgui.CalcTextSize(pct_text).x
            dl:AddText(imgui.ImVec2(p.x + w - pct_w - 12, p.y + 9),
                fade_draw_color(0xFF6AF18B), pct_text)
            local track_x, track_y = p.x + 12, p.y + 34
            local track_w, track_h = w - 24, 6
            dl:AddRectFilled(imgui.ImVec2(track_x, track_y),
                imgui.ImVec2(track_x + track_w, track_y + track_h),
                fade_draw_color(0xFF303A36), track_h / 2)
            if fill_ratio > 0 then
                dl:AddRectFilled(imgui.ImVec2(track_x, track_y),
                    imgui.ImVec2(track_x + math.max(2, track_w * fill_ratio), track_y + track_h),
                    fade_draw_color(0xFF40D76B), track_h / 2)
            end
            local goal_text = '$' .. format_money(earned) .. '  /  $' .. format_money(goal_amount)
            local goal_text_w = imgui.CalcTextSize(goal_text).x
            dl:AddText(imgui.ImVec2(p.x + (w - goal_text_w) / 2, p.y + 50),
                fade_draw_color(0xFFC4CDC7), goal_text)
            imgui.Dummy(imgui.ImVec2(0, h))
        end
        if goal_amount <= 0 then imgui.Spacing() end
        local timer_ratio = math.max(0, math.min(1, 1.0 - elapsed / NOTIFY_DURATION))
        local p = imgui.GetCursorScreenPos()
        local timer_w = imgui.GetContentRegionAvail().x
        local timer_h = 2
        local dl = imgui.GetWindowDrawList()
        dl:AddRectFilled(imgui.ImVec2(p.x, p.y),
            imgui.ImVec2(p.x + timer_w, p.y + timer_h),
            fade_draw_color(0x704B5A57), 1)
        if timer_ratio > 0 then
            dl:AddRectFilled(imgui.ImVec2(p.x, p.y),
                imgui.ImVec2(p.x + timer_w * timer_ratio, p.y + timer_h),
                fade_draw_color(0xD0A4B3AA), 1)
        end
        imgui.Dummy(imgui.ImVec2(0, timer_h + 2))
        imgui.End()
        imgui.PopStyleColor(3)
        imgui.PopStyleVar(4)
        notification_icon_alpha = 1
    end

    local fade_now = os.clock()
    local fade_dt = math.max(0, math.min(fade_now-menu_fade_last,0.1))
    menu_fade_last=fade_now
    local target = menu_open.v and 1 or 0
    menu_fade = menu_fade + (target-menu_fade)*math.min(1,fade_dt*12)
    if menu_open.v then
        imgui.PushStyleVar(imgui.StyleVar.Alpha, math.max(0.05, menu_fade))
        draw_menu()
        update_draw_dialog()
        draw_goal_edit_dialog()
        imgui.PopStyleVar()
    end
end

function main()
    while not isSampAvailable() do wait(100) end

    pcall(function()
        if type(createDirectory) == 'function' then
            createDirectory(script_base() .. '\\config')
        end
    end)

    fa_ensure_font()
    TaxiHelperSound.ensure_yandex()
    update_check()
    history_load()
    meter_load()
    event_load()

    local recovered = tonumber(cfg.session.unfinished) or 0
    if recovered > 0 then
        cfg.day.worked = (tonumber(cfg.day.worked) or 0) + recovered
        cfg.session.unfinished = 0
        history_sync()
        inicfg.save(cfg, config_path)
    end
    check_new_day()
    history_sync()
    reset_session()

    sampRegisterChatCommand('thelper', function()
        menu_open.v = not menu_open.v
        if not menu_open.v then
            goal_keyboard_editor = false
            menu_key_capture = false
        end
    end)

    AHKMessage('Успешно загружен. Меню - /thelper'
        .. ((menu_key > 0) and (' или ' .. key_vk_name(menu_key)) or ''))
    local startup_update_notice_pending = true
    local last_connected = false
    local last_tick = 0
    local last_order_poll = 0

    while true do
        if menu_key_changed then
            menu_key_changed = false
            cfg.ui.menu_key = menu_key
            save()
        end
        if menu_key_capture and not menu_open.v then menu_key_capture = false end
        if goal_keyboard_editor and not menu_open.v then goal_keyboard_editor = false end
        if not menu_open.v or menu_tab ~= 2 then
            if TaxiHelperUi.numericDirty.max_distance then
                TaxiHelperUi.distanceInput.v = format_money(cfg.ui.max_distance or 3500)
                TaxiHelperUi.numericDirty.max_distance = false
                TaxiHelperUi.numericEditActive.max_distance = false
                save()
            end
        end
        imgui.Process = gta and (show.v or notification.active or menu_open.v or meter_edit
            or (meter_show.v and (meter.active or (meter.last_end > 0 and (game_ms() - meter.last_end) < METER_DRAW_LINGER))))
        if startup_update_notice_pending then
            if update_state == 'available' then
                AHKMessage('Доступно обновление TaxiHelper v' .. update_latest .. '.', 0x55FF77)
                startup_update_notice_pending = false
            elseif update_state == 'current' or update_state == 'error' or update_state == 'unconfigured' then
                startup_update_notice_pending = false
            end
        end

        if active then
            local clock = game_ms()
            if catching and clock - catchStart > CATCH_TIMEOUT then
                catching = false
                if lastPicked then
                    order_retry_at[lastPicked] = clock + ORDER_RETRY_DELAY
                    lastPicked = nil
                    lastPickedDist = 0
                end
                order_notify.pickup_seen = false
            end
            if not busy and not catching and clock - last_order_poll >= 10 then
                last_order_poll = clock
                pickBest()
            end
        end

        local t = now()
        if t ~= last_tick then
            last_tick = t
            local ok = sampGetPlayerIdByCharHandle(playerPed)
            local connected = ok and true or false
            if last_connected and not connected then
                finish_work_interval()
                reset_session()
                AHKMessage('Отключение от сервера. Сессия сброшена.')
            end
            last_connected = connected
            if session_start > 0 and t - last_unfinished_save >= UNFINISHED_SAVE_INTERVAL then
                cfg.session.unfinished = math.max(0, t - work_segment_start)
                inicfg.save(cfg, config_path)
                last_unfinished_save = t
            end
            check_new_day()
            if meter.active and meter.last_seen > 0 and game_ms() - meter.last_seen > 180000 then
                meter.active = false
                meter.last_base = math.max(meter.base, meter.peak)
                meter.last_end = game_ms()
                meter.type = ''
            end
            while #pending_deliveries > 0 and t - pending_deliveries[1] > PAYMENT_TIMEOUT do
                table.remove(pending_deliveries, 1)
            end
            waiting_payment = #pending_deliveries > 0
        end

        if rewards_dirty then
            rewards_dirty = false
            save()
        end

        if update_tick() then
            save()
            thisScript():reload()
            return
        end
        wait(10)
    end
end