//
//  Game.swift
//  Labyrinth
//
//  Created by Kate on 26/03/2019.
//  Copyright © 2019 Kate. All rights reserved.
//

import Foundation

public enum Item: String {
    case food = "FOOD"
    case key = "KEY"
    case stash = "STASH"
}

public enum Door: String {
    case N = "N"
    case S = "S"
    case W = "W"
    case E = "E"
}

fileprivate class Room {

    var items = Array<Item>()
    var doors = Set<Door>()
    var (x, y): (Int,Int)        //координаты комнаты в лабиринте
    var avalaibleRoomCoords:[(Int,Int)] = [] //все комнаты, в которые ведут двери (используется для проверки лабиринта на целостность и для подсчета пути от начала до ключа и сундука)
    
    init(_ x: Int,_ y: Int) {
        self.x = x
        self.y = y
    }
    
    func addTheDoor (to targetRoom: Room) { //добавляет соответствующую координатам целевой комнаты дверь в набор и целевую комнату в массив доступных комнат
        switch true {
        case self.x < targetRoom.x:
            self.doors.insert(.E)
        case self.x > targetRoom.x:
            self.doors.insert(.W)
        case self.y > targetRoom.y:
            self.doors.insert(.S)
        case self.y < targetRoom.y:
            self.doors.insert(.N)
        default:
            break
        }
        self.avalaibleRoomCoords.append((targetRoom.x,targetRoom.y))
    }
    
    func info () -> String {  // создает сообщение с описанием комнаты
        var message: String = "Вы заходите в комнату [\(x),\(y)]. "
        if items.isEmpty {
            message.append("Здесь нет предметов, ")
        } else {
            message.append("Здесь находятся предметы: ")
            for item in items {
                message.append(item.rawValue)
                message.append(", ")
            }
        }
        message.removeLast()
        message.removeLast()
        message.append(". ")
        if doors.count > 1 {
            message.append("В комнате есть двери: ")
            for door in doors {
                message.append(door.rawValue)
                message.append(", ")
            }
            message.replaceSubrange(message.lastIndex(of: ",")!...message.lastIndex(of: ",")!, with: ".")
        } else if !doors.isEmpty {
            message.append("В комнате всего одна дверь: \(doors.first!). ")
        }
        
        
        return message
    }
}

extension Room: Hashable { //так как для построения лабиринта используем наборы комнат, приводим в соответствие с протоколом
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
    
}

extension Room: Equatable {
public static func == (lhs: Room, rhs: Room) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
}
//_______________________________________________________

fileprivate struct Labyrinth { //инициализирует комнаты и записывает их в массив, размещает items(stash, key, food)
    
    var room: [[Room]] = []
    var stashCoords: (x:Int,y:Int) //Координаты сундука и ключа сохраняются для
    var keyCoords: (x:Int,y:Int)   //рассчета наиболее короткого пути в лабиринте
                               //(для рассчета здоровья(запаса ходов) игрока)
    
    init(_ countOfLines: Int) { //в основе алгоритма создания лабиринта использован алгоритм Прима
        
        var inLabyrinth = Set<Room>()    // Эти наборы используются
        var nearLabyrinth = Set<Room>()  // для последовательного включения комнат
        var outLabyrinth = Set<Room>()   // в лабиринт
        
        func neiborRooms (x: Int, y: Int, countOfLines: Int) -> [(Int,Int)] {
            //функция возвращает массив соседних клеток (в зависимости от того в какой части лабиринта находится клетка: у стенки, в углу или в середине)
            var neiborRooms:[(Int,Int)] = []
            
            if x > 0 {
                neiborRooms.append((x - 1, y))
            }
            if x < (countOfLines - 1) {
                neiborRooms.append((x + 1, y))
            }
            if y > 0 {
                neiborRooms.append((x, y - 1))
            }
            if y < (countOfLines - 1) {
                neiborRooms.append((x, y + 1))

            }
            return neiborRooms
        }
        
        for x in 0...(countOfLines - 1) { //в цикле инициализируется массив комнат
            room.append([])
            for y in 0...(countOfLines - 1) {
                self.room[x].append(Room(x,y))
                outLabyrinth.insert(self.room[x][y])
                //комната сразу добавляется в набор неприспоединенных к лабиринту комнат
            }
            
        }
        
        if !outLabyrinth.isEmpty {
            //первая комната включается в лабиринт переносом из набора невключенных в лабиринт комнат в набор включенных
            let beginingOfTheLabyrinth: Room = outLabyrinth.removeFirst()
            inLabyrinth.insert(beginingOfTheLabyrinth)
            //все соседние комнаты теперь находятся на границе лабирина, по этому переносятся из набора невключенных комнат в набор соседних с лабиринтом комнат
            for (x,y) in neiborRooms(x: beginingOfTheLabyrinth.x, y: beginingOfTheLabyrinth.y, countOfLines: countOfLines)
            {
                if outLabyrinth.contains(self.room[x][y])
                {
                    nearLabyrinth.insert(outLabyrinth.remove(self.room[x][y])!)
                }
            }
        }
        
        //в цикле, пока не закончатся все граничащие с лабиринтом комнаты, берется одна граничащая с лабиринтом комната, переносится из набора граничащих комнат в набор включенных
        //добавляется дверь, соединяющая ее с включенной комнатой
        //все её соседи, находящиеся в наборе невключенных комнат переносятся в набор граничащих с лабиринтом комнат
        while !nearLabyrinth.isEmpty {
            let addingRoom: Room = nearLabyrinth.removeFirst()
            inLabyrinth.insert(addingRoom)
            for (x,y) in neiborRooms(x: addingRoom.x, y: addingRoom.y, countOfLines: self.room.count)
            {
                
                if outLabyrinth.contains(self.room[x][y])
                {
                    nearLabyrinth.insert(outLabyrinth.remove(self.room[x][y])!)
                }
                else if inLabyrinth.contains(self.room[x][y]),
                    addingRoom.doors.count < 1
                {
                    addingRoom.addTheDoor(to: self.room[x][y])
                    self.room[x][y].addTheDoor(to: addingRoom)
                    if self.room[x][y].doors.count > 3 {self.room[x][y].items.append(.food)}
                }
                
            }
        }
        stashCoords = (Int.random(in: 1..<self.room.count),Int.random(in: 1..<self.room.count))
        self.room[stashCoords.x][stashCoords.y].items.append(.stash)
        keyCoords = (Int.random(in: 1..<self.room.count),Int.random(in: 1..<self.room.count))
        self.room[keyCoords.x][keyCoords.y].items.append(.key)
    }
    
    
    
    func labyrinthLenghtCounter () -> Int { //подсчитывает длинну пути от начала до ключа и сундука
        
        return pathFinder(begin: (0,0), end: keyCoords) + pathFinder(begin: keyCoords, end: stashCoords)
    }
   
    
    //функция нахождения пути построена на основе волнового алгоритма
    //все ячейки маркируются количеством шагов от начальной ячейки пока не будет маркирована конечная ячейка
    //возвращается ранг конечной ячейки
    func pathFinder (begin: (Int, Int), end: (Int, Int)) -> Int {
        
        var labyrinthMap = Array(repeating: Array(repeating: -1, count: self.room.count), count: self.room.count)
        var markedCells = [begin]
        labyrinthMap[begin.0][begin.1] = 0
        
        
        while labyrinthMap[end.0][end.1] == -1 {
            if let markedCell = markedCells.first {
                
                
                for (x,y) in self.room[markedCell.0][markedCell.1].avalaibleRoomCoords {
                    
                    if labyrinthMap[x][y] == -1 {
                        labyrinthMap[x][y] = labyrinthMap[markedCell.0][markedCell.1] + 1
                        markedCells.append((x,y))
                    }
                }
                markedCells.removeFirst()
            }
        }
        
        return labyrinthMap[end.0][end.1]
    }
}



public struct Game {
    
    public var gameOver = false
    private var labyrinth: Labyrinth
    private var playerInventory: Array<Item>
    private var playerHealth: Int
    private var playerAdress: (x: Int, y: Int) {
        didSet {
            playerHealth -= 1
        }
    }
    
    init(_ countOfLines: Int) {
        self.labyrinth = Labyrinth(countOfLines)
        self.playerAdress = (0,0)
        self.playerInventory = Array<Item>()
        self.playerHealth = labyrinth.labyrinthLenghtCounter() * 2 //здоровье рассчитывается исходя из длинны пути от начала лабиринта до ключа и сундука
    }
    
    public mutating func passTheDoor(_ door: Door) -> String {
        if !self.labyrinth.room[playerAdress.x][playerAdress.y].doors.contains(door) {
            return "Нет такой двери"
        }
        if playerHealth > 0 {
            switch door {
            case .N:
                self.playerAdress.y += 1
            case .S:
                self.playerAdress.y -= 1
            case .W:
                self.playerAdress.x -= 1
            case .E:
                self.playerAdress.x += 1
            }
            return self.roomInfo()
        } else {
            gameOver = true
            return "Ваш запас ходов исчерпан, игра окончена"
        }
    }
    public mutating func addToInventory (_ item: Item) -> String {
        if item != .stash, self.labyrinth.room[playerAdress.x][playerAdress.y].items.contains(item) {
            self.playerInventory.append(item)
            self.labyrinth.room[playerAdress.x][playerAdress.y].items.remove(at: self.labyrinth.room[playerAdress.x][playerAdress.y].items.lastIndex(of: item)!)
            return "Предмет добавлен в инвентарь"
        }
        else if item == .stash{
            return "Сундук нельзя взять с собой"
        }
        else {
            return "Такого предмета нет в комнате"
        }
    }
    public mutating func removeFromInventory (_ item: Item) -> String {
        if playerInventory.contains(item) {
            self.playerInventory.remove(at: self.playerInventory.lastIndex(of: item)!)
            self.labyrinth.room[playerAdress.x][playerAdress.y].items.append(item)
            return "Вы оставляете предмет в комнате на полу"
        }
        return "Нет такого предмета в инвентаре"
    }
    
    public mutating func useItem (_ item: Item) -> String { //предмет можно использовать если он есть в комнтате, где находится игрок или в инвентаре
        if playerInventory.contains(item) || self.labyrinth.room[playerAdress.x][playerAdress.y].items.contains(item) {
            switch item {
            case .stash, .key:
                if (self.playerInventory.contains(.key) || self.labyrinth.room[playerAdress.x][playerAdress.y].items.contains(.key)), self.labyrinth.room[playerAdress.x][playerAdress.y].items.contains(.stash) {
                    gameOver = true
                    return "Грааль найден! Вы победили!"
                }
                else if !self.labyrinth.room[playerAdress.x][playerAdress.y].items.contains(.stash) {
                    return "Чтобы использовать ключ, нужно найти сундук!"
                }
                else {
                    return "Чтобы открыть сундук, нужен ключ!"
                }
            case .food:
                playerHealth += 10
                if self.playerInventory.contains(item) {
                    self.playerInventory.remove(at: self.playerInventory.lastIndex(of: item)!)
                    return "Вы чувствуете, как силы прибавляются"
                } else {
                    self.labyrinth.room[playerAdress.x][playerAdress.y].items.remove(at:  self.labyrinth.room[playerAdress.x][playerAdress.y].items.lastIndex(of: item)!)
                    return "Вы чувствуете, как силы прибавляются"
                }
            }
        }
        return "Такого предмета нет в комнате"
    }
    public func roomInfo() -> String { //генерируется сообщение с информацией о комнате и об игроке
        var message: String = "В вашем инвентаре"
        if playerInventory.isEmpty {
            message.append(" нет предметов, ")
        } else {
            message.append(": ")
            for item in playerInventory {
                message.append(item.rawValue)
                message.append(", ")
            }
        }
        message.replaceSubrange(message.lastIndex(of: ",")!...message.lastIndex(of: ",")!, with: ".")
        return (self.labyrinth.room[playerAdress.x][playerAdress.y].info() + message + "У Вас хватит сил еще на \(playerHealth) ходов. ")
        
    }
    
    public func showLabyrinth() -> String { //ненужная функция, любопытства ради. Позволяет увидеть лабиринт и координаты ключа и сундука
        var printString = "_"
        for _ in (0...self.labyrinth.room.count - 1)  {
            printString.append("__")
        }
        printString.append("\n")
        for y in (0...self.labyrinth.room.count - 1).reversed()  {
            printString.append("|")
            for x in 0...self.labyrinth.room.count - 1 {
                if (x,y) == labyrinth.keyCoords,
                    (x,y) == labyrinth.stashCoords{
                    printString.append("x")
                }
                else if (x,y) == labyrinth.keyCoords {
                    printString.append("k")
                }
                else if (x,y) == labyrinth.stashCoords {
                    printString.append("s")
                }
                else {
                if self.labyrinth.room[x][y].doors.contains(.S) {
                    printString.append(" ")
                }
                else {
                    printString.append("_")
                }
                }
                if self.labyrinth.room[x][y].doors.contains(.E) {
                    printString.append("_")
                }
                else {
                    printString.append("|")
                }
                
            }
            printString.append("\n")
        }
        return printString
    }
}
