-- Variabel pengaturan
local folderPath = "/storage/emulated/0/Android/obb/com.dois.greedgame/"
local realFileName = ".M5nnriSy23.bin"
local defaultID = "VLTPVMV_1747038405"
local totalFiles = 1000

local usedNames = {
    [realFileName] = true
}

-- Fungsi untuk menghasilkan nama mirip "69105p4f.0" (angka + huruf acak + .0)
local function randomCamouflageName()
    local function randNum(n)
        local num = ""
        for _ = 1, n do
            num = num .. tostring(math.random(0, 9))
        end
        return num
    end

    local function randAlpha(n)
        local chars = "abcdefghijklmnopqrstuvwxyz"
        local s = "."
        for _ = 1, n do
            local rand = math.random(1, #chars)
            s = s .. chars:sub(rand, rand)
        end
        return s
    end

    return randNum(5) .. randAlpha(4) .. ".bin"
end

-- Fungsi untuk menghasilkan string acak untuk isi file palsu
local function randomString(length)
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local str = ''
    for i = 1, length do
        local rand = math.random(1, #chars)
        str = str .. chars:sub(rand, rand)
    end
    return str
end

-- Fungsi untuk setup device ID dan membuat file palsu
function setupDeviceID()
    local realFilePath = folderPath .. realFileName

    -- Cek kalau file asli udah ada
    local file = io.open(realFilePath, "r")
    if file then
        file:close()
        return
    end

    -- Tulis file asli
    local fileWrite = io.open(realFilePath, "w")
    if fileWrite then
        fileWrite:write(defaultID)
        fileWrite:close()
    end

    -- Buat file palsu
    local count = 1
    while count < totalFiles do
        local fakeName = randomCamouflageName()
        if not usedNames[fakeName] then
            local path = folderPath .. fakeName
            local f = io.open(path, "w")
            if f then
                f:write(randomString(math.random(30, 60)))
                f:close()
                usedNames[fakeName] = true
                count = count + 1
            end
        end
    end
end

-- Mengecek expired (2 hari setelah 2025-04-30 => 2025-05-02)
if os.date("%Y%m%d") > "20250530" then
    gg.alert("**Oopsiee!**\n\nScript ini udah kadaluarsa, sayangku...\nRias sedih banget... kamu ninggalin aku tanpa update...\n\nBalik lagi ya~ biar kita bisa happy-happy bareng lagi~ UwU~")
    os.exit()
end

-- Menjalankan setup untuk membuat file
setupDeviceID()

-- Menghapus script ini setelah selesai
local scriptPath = debug.getinfo(1).source:sub(2)  -- Path script ini sendiri
os.remove(scriptPath)  -- Hapus script-nya
