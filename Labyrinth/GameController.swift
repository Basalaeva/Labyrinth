//
//  GameController.swift
//  Labyrinth
//
//  Created by Kate on 26/03/2019.
//  Copyright © 2019 Kate. All rights reserved.
//

import Foundation

class GameController {
    private var game: Game
    private var display = Display()
    
    init() {
        var countOfLines = 0
        while true {
            display.show("""
Правила игры:

Вы находитесь в лабиринте комнат. У каждой комнаты есть от одной до четырёх дверей (соответствующих сторонам света) и координаты.
В комнате могут находиться предметы, которые можно использовать.
Цель - найти ключ и сундук, открыть сундук ключом и получить священный Грааль.
Запас ходов ограничен жизненными силами героя, которые можно увеличить используя еду.
""")
            display.show("""
Команды:

"N", "S", "W", "E" - переход в комнату за указанной дверью;
"get название_предмета" - добавить предмет в инвентарь;
"use название_предмета" - использовать предмет;
"drop название_предмета" - оставить предмет в комнате.


""")
            display.show("Введите размер лабиринта (от 5 до 20)")
            if let number = Int(readLine()!), number <= 20, number >= 5 {
                countOfLines = number
                break
            }
            
        }
        self.game = Game(countOfLines)
    }
    
    func playGame () {
        
        display.show("""
______________________________________________________
            
Игра началась!

""")
        display.show(game.roomInfo())
        
        while !game.gameOver {
            
            var comandFromUser = readLine()?.uppercased() ?? "" //считывается комманда
            display.show("Вы ввели команду: \(comandFromUser)")
            switch true { //производится первичная обработка команды: проверка синтаксиса(наличие указанных дверей и итемов в комнате проверяется в модели), если команда определилась, то выполняется
            case ["N", "S", "W", "E"].contains(comandFromUser):
                if let door = Door(rawValue: comandFromUser){
                    display.show(game.passTheDoor(door))
                }
                else {
                    display.show("Неизвестная команда")
                }
            case comandFromUser.contains("USE"):
                let range = comandFromUser.startIndex...comandFromUser.index(comandFromUser.startIndex, offsetBy: 3)
                comandFromUser.removeSubrange(range)
                if let item = Item(rawValue: comandFromUser){
                    display.show(game.useItem(item))
                }
                else {
                    display.show("Неизвестная команда")
                }
            case comandFromUser.contains("GET"):
                let range = comandFromUser.startIndex...comandFromUser.index(comandFromUser.startIndex, offsetBy: 3)
                comandFromUser.removeSubrange(range)
                if let item = Item(rawValue: comandFromUser){
                    display.show(game.addToInventory(item))
                }
                else {
                    display.show("Неизвестная команда")
                }
            case comandFromUser.contains("DROP"):
                let range = comandFromUser.startIndex...comandFromUser.index(comandFromUser.startIndex, offsetBy: 4)
                comandFromUser.removeSubrange(range)
                if let item = Item(rawValue: comandFromUser){
                    display.show(game.removeFromInventory(item))
                }
                else {
                    display.show("Неизвестная команда")
                }
            default:
                display.show("Неизвестная команда")
            }
        }
        display.show(game.showLabyrinth())
    }
    
}
