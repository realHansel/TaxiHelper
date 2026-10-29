script_name('Taxi Helper 2.2')
script_version('2.2')

require 'lib.moonloader'
local sampev = require 'samp.events'
local imgui = require 'imgui'
local inicfg = require 'inicfg'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local config_path = 'TaxiHelper.ini'

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
    menu_title   = 'Taxi Helper  v2.2',
    menu_sub     = u8'Статистика поездок и настройки',
    tab_main     = u8'Главная',
    tab_settings = u8'Настройки',
    tab_logs     = u8'История',
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
    reset_day_btn = u8'Сбросить статистику за день',
    reset_confirm = u8'Нажми ещё раз для подтверждения',
    sec_orders   = u8'ЛОВЛЯ ЗАКАЗОВ',
    order_dist   = u8'Макс. дистанция (м)',
    bot_only     = u8'Принимать заказы только от ботов',
}

local DOLLAR_COLOR     = imgui.ImVec4(0.35, 1.0, 0.35, 1.0)
local HEADER_DAY_COLOR = imgui.ImVec4(0.55, 0.85, 1.0, 1.0)
local TAXI_YELLOW      = imgui.ImVec4(0.26, 0.98, 0.26, 1.0)
local TAXI_WHITE       = imgui.ImVec4(1.0, 1.0, 1.0, 1.0)
local WINDOW_BG        = imgui.ImVec4(0.045, 0.055, 0.075, 0.70)
local WINDOW_BORDER    = imgui.ImVec4(0.26, 0.98, 0.26, 0.35)
local PANEL_BG         = imgui.ImVec4(0.075, 0.085, 0.11, 0.98)

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

local orders     = {}
local lastPicked = nil

local AUTO          = true
local NEAREST       = true
local CATCH_TIMEOUT = 1.5

local DIALOG_CONFIRM = 15324
local DIALOG_START   = 26919

local menu_open      = imgui.ImBool(false)
local dragStartPos   = nil

local gta = true
addEventHandler("onWindowMessage", function(msg, wparam)
    if msg == 6 then
        gta = wparam ~= 0
    end


    if msg == 0x100 then 
        if wparam == 0x1B then 
            if menu_open.v then
                menu_open.v = false
                imgui.ShowCursor = false
                consumeWindowMessage(true, false)
            end
        end
    end
end)

local defaults = {
    window  = { x = 100, y = 100, show = true },
    session = { rides = 0, money = 0, best_ride = 0, unfinished = 0 },
    day     = { date = '', rides = 0, money = 0, worked = 0, boxes = 0, coins = 0, tips = 0, tips_cash = 0 },
    ui      = { notify = 1, s_rides = 1, s_money = 1, s_avg = 1, s_time = 1,
                d_money = 1, d_worked = 1, d_rides = 1, d_boxes = 1, d_coins = 1, d_tips = 1, d_avg = 0,
                max_distance = 3500, bot_only = 0 }
}

local cfg = inicfg.load(defaults, config_path)

local UI_DEFAULTS = {
    notify = 1, s_rides = 1, s_money = 1, s_avg = 1, s_time = 1,
    d_money = 1, d_worked = 1, d_rides = 1, d_boxes = 1, d_coins = 1, d_tips = 1, d_avg = 0,
    max_distance = 3500, bot_only = 0
}

if type(cfg.ui) ~= 'table' then cfg.ui = {} end

local uib = {}
for key, def in pairs(UI_DEFAULTS) do
    local v = tonumber(cfg.ui[key])
    if v == nil then v = def end
    if key == 'max_distance' then
        uib[key] = imgui.ImInt(v)
    else
        uib[key] = imgui.ImBool(v == 1)
    end
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
    day_money = 0
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
    return getWorkingDirectory() .. '\\config\\TaxiHelper_events.json'
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

local function show_ride_notification(money, force)
    if not force and not uib.notify.v then return end
    notification.active = true
    notification_show.v = true
    notification.started = game_ms()
    notification.ride_money = money
    notification.session_money = tonumber(cfg.session.money) or 0
    notification.day_money = tonumber(cfg.day.money) or 0
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
    return getWorkingDirectory() .. '\\config\\TaxiHelper_history.json'
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

local bot_call_notices = {}
local bot_cef_unmatched = {}
local bot_known_order_ids = {}
local bot_approved_order_ids = {}
local BOT_MATCH_MS = 5000
local BOT_SETTLE_MS = 350
local BOT_APPROVAL_MS = 15000
local bot_last_player_notice = -100000

local function bot_reset_tracking()
    bot_call_notices = {}
    bot_cef_unmatched = {}
    bot_known_order_ids = {}
    bot_approved_order_ids = {}
    bot_last_player_notice = -100000
end

local function bot_register_chat_call(clean)
    if not active or not uib.bot_only.v then return end
    local is_bot = clean:match('^%[Такси%]%s*Поступил новый заказ%s*%(%s*клиент:%s*[^,%)]+') ~= nil
    local is_player = clean:match('^%[Такси%]%s*Поступил новый заказ от%s+[^%s%(]+') ~= nil
    if not is_bot and not is_player then return end
    local ms = game_ms()
    bot_call_notices[#bot_call_notices + 1] = {kind = is_bot and 'bot' or 'player', t = ms}
    if is_player then bot_last_player_notice = ms end
end

local function bot_resolve_calls()
    if not active or not uib.bot_only.v or busy or catching then return end
    local t = game_ms()
    local remaining_notices = {}
    for _, n in ipairs(bot_call_notices) do
        if t - n.t <= BOT_MATCH_MS then
            remaining_notices[#remaining_notices + 1] = n
        end
    end
    bot_call_notices = remaining_notices

    local pending = {}
    for id, meta in pairs(bot_cef_unmatched) do
        if t - meta.t <= BOT_MATCH_MS and orders[id] then
            pending[#pending + 1] = {id = id, t = meta.t}
        else
            bot_cef_unmatched[id] = nil
        end
    end
    if #pending == 0 or #bot_call_notices == 0 then return end
    if #pending ~= #bot_call_notices then return end

    local only_bot, only_player, earliest = true, true, t
    for _, n in ipairs(bot_call_notices) do
        if n.kind ~= 'bot' then only_bot = false end
        if n.kind ~= 'player' then only_player = false end
        if n.t < earliest then earliest = n.t end
    end
    for _, v in ipairs(pending) do
        if v.t < earliest then earliest = v.t end
    end
    if t - earliest < BOT_SETTLE_MS then return end
    if not only_bot and not only_player then return end
    if only_bot and t - bot_last_player_notice < BOT_MATCH_MS then return end

    for _, v in ipairs(pending) do
        bot_cef_unmatched[v.id] = nil
        if only_bot then
            bot_approved_order_ids[v.id] = t
        else
            orders[v.id] = nil
            bot_approved_order_ids[v.id] = nil
        end
    end
    bot_call_notices = {}
    if only_bot then pickBest() end
end

function setActive(state, reason)
    if active == state then return end
    active = state
    busy, catching = false, false
    orders, lastPicked = {}, nil
    bot_reset_tracking()
    local suffix = reason and (' (' .. reason .. ')') or ''
    if active then
        AHKMessage('Ловля ON - ожидание заказов' .. suffix, 0x00FF00)
    else
        AHKMessage('Ловля OFF' .. suffix, 0xFF0000)
    end
end

function pickBest()
    if busy or catching then return end

    local bestId, bestDist
    for oid, dist in pairs(orders) do
        local allowed = not uib.bot_only.v or
            (bot_approved_order_ids[oid] and game_ms() - bot_approved_order_ids[oid] <= BOT_APPROVAL_MS)
        if allowed and (not bestDist or (NEAREST and dist < bestDist)) then
            bestId, bestDist = oid, dist
            if not NEAREST then break end
        end
    end

    if bestId then
        lastPicked = bestId
        catching = true
        catchStart = os.clock()
        sendcef('pickOrderWorker|' .. bestId)
        AHKMessage(('Ловлю #%d (%d м)'):format(bestId, bestDist), 0xFFFF00)
    end
end

local function onCef(str)
    if not active then return end

    if str:find('event.arizonaDriver.initializeClearOrders', 1, true) then
        if uib.bot_only.v and not catching then
            orders = {}
            bot_cef_unmatched = {}
            bot_known_order_ids = {}
            bot_approved_order_ids = {}
        end
        return
    end

    if str:find('event.arizonaDriver.initializeOrders', 1, true) then
        if busy then return end
        local max_dist = tonumber(uib.max_distance.v) or 3500
        for obj in str:gmatch('{(.-)}') do
            local oid    = tonumber(obj:match('"id":(%d+)'))
            local dist   = tonumber(obj:match('"distance":(%d+)'))
            local free   = obj:match('"active":(%d+)') == '0'
            local ok = oid and dist and free and (not max_dist or dist <= max_dist)
            if ok then
                orders[oid] = dist
                if uib.bot_only.v and not bot_known_order_ids[oid] then
                    bot_cef_unmatched[oid] = {t = game_ms()}
                    bot_known_order_ids[oid] = true
                end
            end
        end
        pickBest()
        return
    end

    if str:find('initializeDriverPage', 1, true) and str:find('"order"', 1, true) then
        busy = true
        catching = false
        orders = {}
        bot_reset_tracking()
        AHKMessage('Заказ пойман -> везём', 0x00FF00)
        return
    end

    if busy and str:find('updateCustomizedCounterVisibility', 1, true) and str:find('false', 1, true) then
        busy = false
        orders = {}
        bot_reset_tracking()
        AHKMessage('Доставил -> ждём заказ', 0x00FF00)
    end
end

local function process_cef(str)
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
    bot_register_chat_call(clean)

    if AUTO and active then
        if clean:find('Вы закончили работу таксистом', 1, true) then
            setActive(false, 'работа закончена')
        elseif clean:find('Вы прервали заказ', 1, true) then
            busy, catching = false, false
            orders = {}
            bot_reset_tracking()
            AHKMessage('Заказ прерван -> ждём новый', 0xFFAA00)
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
        event_add("Смена завершена")
        save()
    elseif clean:find('Ларцов за выполненный заказ') then
        local n = clean:match('%+(%d+)%s*Ларцов')
        if n then pending_boxes = tonumber(n) end
    elseif clean:find('Вы доставили клиента по имени') then
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

    if not active then return end

    if id == DIALOG_CONFIRM and text:find('Вы хотите принять этот вызов', 1, true) then
        sampSendDialogResponse(id, 1, -1, '')
        return false
    end

    if text:find('Заказ уже принят или отменён', 1, true) then
        sampSendDialogResponse(id, 1, -1, '')
        if lastPicked then orders[lastPicked] = nil end
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
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end

function AHKMessage(text, color)
    sampAddChatMessage('{AA66FF}[Taxi Helper]{FFFFFF} ' .. tostring(text), color or -1)
end


local UPDATE_CURRENT_VERSION = '2.2'
local UPDATE_INFO_URL = 'https://raw.githubusercontent.com/realHansel/TaxiHelper/main/info.upd'
local UPDATE_SCRIPT_URL = 'https://raw.githubusercontent.com/realHansel/TaxiHelper/main/TaxiHelper.lua'
local UPDATE_DLSTATUS = require('moonloader').download_status
local update_state = 'idle'
local update_latest = ''
local update_error = ''
local update_started = 0
local update_token = 0
local update_ready = false
local update_temp_script = nil

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
    update_token = update_token + 1
    local token = update_token
    update_started = os.time()
    local path = getWorkingDirectory() .. '\\config\\TaxiHelper_update_info.tmp'
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
                update_state = update_newer(update_latest, UPDATE_CURRENT_VERSION) and 'available' or 'current'
                print('[TaxiHelper / Updater] Latest: ' .. update_latest .. '; installed: ' .. UPDATE_CURRENT_VERSION)
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
    if update_state == 'current' then return u8'Версия актуальна' end
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
            update_download()
        elseif update_state == 'checking' or update_state == 'downloading' or update_state == 'installing' then
        elseif update_state == 'unconfigured' then
            AHKMessage('Ссылка на обновления не настроена. Заполните UPDATE_INFO_URL и UPDATE_SCRIPT_URL в Lua-файле.')
        else
            update_check()
        end
    end
    imgui.PopStyleColor(2)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        if update_state == 'error' then
            imgui.Text(u8(update_error))
        elseif update_state == 'unconfigured' then
            imgui.Text(u8'Для автообновления нужны ссылки на ваш GitHub-репозиторий')
        else
            imgui.Text(u8'Установлена версия: ' .. UPDATE_CURRENT_VERSION)
        end
        imgui.EndTooltip()
    end
    imgui.SetCursorScreenPos(imgui.ImVec2(pos.x, pos.y + 36))
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

local fa_font = nil
local fa_attempted = false
local fa_ranges = nil
local fa_glyphs_verified = false
local fa_glyphs_ok = false
local fa_icon_warning = false
local FA_URL = 'https://raw.githubusercontent.com/FortAwesome/Font-Awesome/v4.7.0/fonts/fontawesome-webfont.ttf'
local FA_PATH = getWorkingDirectory() .. '\\resource\\fonts\\fontawesome-webfont.ttf'
local FA_TEMP = FA_PATH .. '.download'
local fa_downloading = false
local fa_download_checked = false
local fa_dlstatus = require('moonloader').download_status

local function fa_valid_file(path)
    local f = io.open(path, 'rb')
    if not f then return false end
    local header = f:read(4)
    local size = f:seek('end') or 0
    f:close()
    return size > 20000 and (header == string.char(0, 1, 0, 0) or header == 'OTTO' or header == 'true')
end

local function fa_log(msg)
    print('[Taxi Helper / Font Awesome] ' .. msg)
end

local function fa_ensure_font()
    if fa_download_checked then return end
    fa_download_checked = true
    fa_log('Checking font: ' .. FA_PATH)
    if fa_valid_file(FA_PATH) then
        fa_log('Font file found.')
        return
    end
    if type(downloadUrlToFile) ~= 'function' then
        fa_log('downloadUrlToFile unavailable; install font manually.')
        return
    end
    local dir = getWorkingDirectory() .. '\\resource\\fonts'
    if type(createDirectory) == 'function' then
        pcall(createDirectory, getWorkingDirectory() .. '\\resource')
        pcall(createDirectory, dir)
    end
    os.remove(FA_TEMP)
    fa_downloading = true
    fa_log('Font missing; downloading Font Awesome 4.7 from official GitHub...')
    local ok, err = pcall(function()
        downloadUrlToFile(FA_URL, FA_TEMP, function(id, status, p1, p2)
            local ds = fa_dlstatus
            if ds and status == ds.STATUS_ENDDOWNLOADDATA then
                fa_downloading = false
                if fa_valid_file(FA_TEMP) then

                    if not fa_valid_file(FA_PATH) then
                        os.remove(FA_PATH)
                        local renamed = os.rename(FA_TEMP, FA_PATH)
                        if not renamed then
                            fa_log('Could not move downloaded font into fonts directory.')
                            return
                        end
                    else
                        os.remove(FA_TEMP)
                    end
                    fa_log('Font downloaded. Reload TaxiHelper or restart game to enable icons.')
                else
                    os.remove(FA_TEMP)
                    fa_log('Downloaded font is invalid; continuing with fallback icons.')
                end
            elseif ds and (status == ds.STATUS_ERROR or status == ds.STATUSEX_ENDDOWNLOAD) then
                fa_downloading = false
                if fa_valid_file(FA_TEMP) then
                    if not fa_valid_file(FA_PATH) then
                        os.remove(FA_PATH)
                        if os.rename(FA_TEMP, FA_PATH) then
                            fa_log('Font downloaded. Reload TaxiHelper to enable icons.')
                        else
                            fa_log('Could not move downloaded font into fonts directory.')
                        end
                    else
                        os.remove(FA_TEMP)
                    end
                else
                    os.remove(FA_TEMP)
                    fa_log('Download ended without a valid font; check internet and MoonLoader log.')
                end
            end
        end)
    end)
    if not ok then
        fa_downloading = false
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
    if not fa_attempted and not fa_downloading then
        fa_attempted = true
        local ok, err = pcall(function()
            local ffi = require 'ffi'
            fa_ranges = imgui.ImGlyphRanges({0xF000, 0xF2FF})
            if not fa_valid_file(FA_PATH) then
                fa_log('Font file not found or invalid: ' .. FA_PATH)
                return
            end
            fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF(FA_PATH, 14.0, nil, fa_ranges)
            if fa_font == nil then
                fa_log('AddFontFromFileTTF returned nil')
            else
                fa_log('Font Awesome registered with imgui.ImGlyphRanges.')
            end
        end)
        if not ok then fa_log('Font initialization error: ' .. tostring(err)) end
    end
end

local ACCENT      = imgui.ImVec4(0.26, 0.98, 0.26, 1.00)
local MUTED       = imgui.ImVec4(0.62, 0.64, 0.70, 1.00)

local menu_tab       = 1
local reset_day_confirm = false
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


    fa_glyphs_ok = fa_font ~= nil
    if fa_font and fa_glyphs_ok then
        local ok, err = pcall(function()
            imgui.SetCursorScreenPos(imgui.ImVec2(x, y))
            imgui.PushFont(fa_font)
            local text_ok, text_err = pcall(imgui.Text, ICONS[kind] or ICONS.stats)
            imgui.PopFont()
            if not text_ok then error(text_err) end
        end)
        rendered = ok
        if not ok and not fa_draw_error_logged then
            fa_draw_error_logged = true
            fa_log('Icon drawing error: ' .. tostring(err))
        end
    end
    if not rendered then
        if fa_font and not fa_glyphs_ok and not fa_icon_warning then
            fa_icon_warning = true
            fa_log('Icon glyphs missing from atlas; using text fallback. Check font file and ImGui font atlas rebuild.')
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
    if fa_font then
        pcall(function()
            imgui.PushFont(fa_font)
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
    if label == L.opt_notify then return 'notify' end
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


local rhAnimT = {}
local function rhAnim(key, target, speed)
    local now = os.clock()
    local s = rhAnimT[key]
    if not s then s = {v = target, t = now}; rhAnimT[key] = s end
    local dt = math.min(now - s.t, 0.05)
    s.t = now
    s.v = s.v + (target - s.v) * math.min(1, dt * (speed or 14))
    if math.abs(target - s.v) < 0.002 then s.v = target end
    return s.v
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
    local yesterday = os.date('%Y-%m-%d', os.time()-86400)
    local yesterday_money = tonumber(history[yesterday] and history[yesterday].money) or 0
    for i=0,6 do
        local date = os.date('%Y-%m-%d', os.time()-i*86400)
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

local function draw_settings()
    imgui.BeginChild('##settings', imgui.ImVec2(0, 0), false)

    menu_section(L.sec_windows)
    if ui_toggle('stats', L.opt_stats, show) then save() end
    if ui_toggle('notify', L.opt_notify, uib.notify) then ui_commit('notify') end
    imgui.Spacing()
    if imgui.Button('[+] ' .. L.btn_move, imgui.ImVec2(260, 30)) then
        edit_mode = true
        show.v = true
        menu_open.v = false
    end

    menu_section(L.sec_session)
    for _, it in ipairs(SESSION_ITEMS) do
        if ui_toggle(it.key, it.label, uib[it.key]) then ui_commit(it.key) end
    end

    menu_section(L.sec_day)
    for _, it in ipairs(DAY_ITEMS) do
        if ui_toggle(it.key, it.label, uib[it.key]) then ui_commit(it.key) end
    end

    menu_section(L.sec_orders)
    if ui_toggle('bot_only', L.bot_only, uib.bot_only) then
        ui_commit('bot_only')
        orders = {}
        bot_reset_tracking()
    end
    icon_text('distance', L.order_dist)
    imgui.SameLine(200)
    imgui.PushItemWidth(120)
    if imgui.InputInt('##max_dist', uib.max_distance, 100, 500) then
        if uib.max_distance.v < 100 then uib.max_distance.v = 100 end
        cfg.ui.max_distance = uib.max_distance.v
        save()
    end
    imgui.PopItemWidth()

    imgui.EndChild()
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
    if imgui.SmallButton('<##prev_month') then calendar_month_shift(-1) end
    imgui.SameLine()
    imgui.Text(string.format('%02d.%04d', calendar_month, calendar_year))
    imgui.SameLine()
    if imgui.SmallButton('>##next_month') then calendar_month_shift(1) end
    imgui.SameLine()
    if imgui.SmallButton(u8'Сегодня##cal_today') then
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
        if entry and (tonumber(entry.money) or 0)>0 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.10,0.35,0.17,0.9))
        end
        if imgui.Button(label,imgui.ImVec2(38,23)) then calendar_selected=date end
        if entry and (tonumber(entry.money) or 0)>0 then imgui.PopStyleColor() end
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
local function draw_events()
    imgui.TextColored(ACCENT, u8'ЖУРНАЛ УВЕДОМЛЕНИЙ')
    imgui.TextColored(MUTED, u8'Последние ' .. tostring(EVENT_LIMIT) .. ' событий')
    imgui.Separator()
    imgui.BeginChild('##event_list', imgui.ImVec2(0,0), true)
    if #event_log == 0 then imgui.TextDisabled(u8'Пока нет событий') end
    for _, e in ipairs(event_log) do
        imgui.TextColored(MUTED, e.time)
        imgui.SameLine(170)
        imgui.Text(u8(e.text))
    end
    imgui.EndChild()
end

local function draw_logs()
    if imgui.Button(u8'История по дням##hist_days') then history_view=1 end
    imgui.SameLine()
    if imgui.Button(u8'Календарь##hist_calendar') then history_view=2 end
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

local function draw_with_animation(draw_func)
    draw_func()
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


    if imgui.IsMouseHoveringRect(winPos, imgui.ImVec2(winPos.x + winSize.x, winPos.y + titleBarHeight), false) and not imgui.IsMouseHoveringRect(imgui.ImVec2(winPos.x + winSize.x - 280, winPos.y + 12), imgui.ImVec2(winPos.x + winSize.x, winPos.y + 60), false) then
        if imgui.IsMouseDown(0) then
            local mousePos = imgui.GetMousePos()
            if not dragStartPos then
                dragStartPos = { x = mousePos.x - winPos.x, y = mousePos.y - winPos.y }
            end
            imgui.SetWindowPos(imgui.ImVec2(mousePos.x - dragStartPos.x, mousePos.y - dragStartPos.y))
        else
            dragStartPos = nil
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

    draw_with_animation(function()
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
    end)

    imgui.EndChild()

    imgui.PopFont()
    imgui.End()
    imgui.PopStyleColor(2)
    imgui.PopStyleVar(5)
end

function imgui.OnDrawFrame()
    imgui.ShowCursor = edit_mode or menu_open.v
    imgui.LockPlayer = menu_open.v

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

    local alpha = notification_alpha()
    if alpha > 0 then
        local io = imgui.GetIO()
        local flagsNotify = imgui.WindowFlags.NoTitleBar
            + imgui.WindowFlags.NoResize
            + imgui.WindowFlags.NoMove
            + imgui.WindowFlags.NoSavedSettings
            + imgui.WindowFlags.NoInputs

        local elapsed = game_ms() - notification.started


        local bg_alpha = 1
        local text_alpha = 1
        notification_icon_alpha = alpha


        imgui.SetNextWindowSize(imgui.ImVec2(395, 174), imgui.Cond.Always)
        imgui.SetNextWindowPos(
            imgui.ImVec2(io.DisplaySize.x * 0.5, io.DisplaySize.y * 0.12 + (1.0 - alpha) * 12),
            imgui.Cond.Always,
            imgui.ImVec2(0.5, 0.0)
        )

        imgui.PushStyleVar(imgui.StyleVar.Alpha, alpha)
        imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 11)
        imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(16, 12))
        imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(7, 5))

        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.04, 0.05, 0.07, 0.85 * bg_alpha))
        imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(1.0, 0.85, 0.2, 0.8 * bg_alpha))
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 1.0, 1.0, text_alpha))

        notification_show.v = true
        imgui.Begin(L.notify_id, notification_show, flagsNotify)

        imgui.PushFont(fontsizeNotifyBig)
        local title = L.ride_done
        local title_w = imgui.CalcTextSize(title).x
        imgui.SetCursorPosX((imgui.GetWindowWidth() - title_w) / 2)

        local pulse = (0.9 + 0.1 * math.sin(elapsed / 260)) * text_alpha
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

        imgui.TextColored(imgui.ImVec4(0.35, 1.0, 0.35, text_alpha), plus)

        imgui.Spacing()

        imgui.Separator()
        imgui.Spacing()


        local amount_x = 233
        icon_text('earned', L.session_sum)
        imgui.SameLine(amount_x)
        imgui.TextColored(imgui.ImVec4(0.35, 1.0, 0.35, text_alpha), '$ ' .. format_money(notification.session_money))

        icon_text('day', L.day_sum)
        imgui.SameLine(amount_x)
        imgui.TextColored(imgui.ImVec4(0.35, 1.0, 0.35, text_alpha), '$ ' .. format_money(notification.day_money))

        imgui.PopFont()

        imgui.Spacing()
        imgui.Spacing()

        local progress = 1.0 - (elapsed / NOTIFY_DURATION)
        progress = math.max(0, math.min(1, progress))

        local p = imgui.GetCursorScreenPos()
        local bar_width = imgui.GetContentRegionAvail().x
        local bar_height = 4

        local dl = imgui.GetWindowDrawList()

        dl:AddRectFilled(
            imgui.ImVec2(p.x, p.y), 
            imgui.ImVec2(p.x + bar_width, p.y + bar_height), 
            imgui.ImColor(255, 255, 255, 30 * text_alpha):GetU32(), 
            bar_height / 2
        )

        dl:AddRectFilled(
            imgui.ImVec2(p.x, p.y), 
            imgui.ImVec2(p.x + (bar_width * progress), p.y + bar_height), 
            imgui.ImColor(66, 220, 82, 255 * text_alpha):GetU32(), 
            bar_height / 2
        )

        imgui.Dummy(imgui.ImVec2(0, bar_height + 5))

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
        imgui.PopStyleVar()
    end
end

function main()
    while not isSampAvailable() do wait(100) end

    fa_ensure_font()
    update_check()
    history_load()
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
    end)


    AHKMessage('успешно загружен. Меню - /thelper')

    local last_connected = false
    local last_tick = 0

    while true do
        imgui.Process = gta and (show.v or notification.active or menu_open.v)

        if active then
            bot_resolve_calls()
            local clock = os.clock()
            if catching and clock - catchStart > CATCH_TIMEOUT then
                catching = false
                if lastPicked then orders[lastPicked] = nil end
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
            wait(300)
            thisScript():reload()
            return
        end
        wait(50)
    end
end