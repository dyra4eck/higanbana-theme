-- Higanbana: скруглённая рамка вокруг всех панелей, git-статус, открытие нескольких файлов
require("full-border"):setup { set = "rounded" }
require("git"):setup { order = 1500 }
require("smart-enter"):setup { open_multi = true }
