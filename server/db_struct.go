package main

import (
	"go.mongodb.org/mongo-driver/mongo"
)

// UserCollection is the DB for users, it's name is defined after main() function.
var UserCollection *mongo.Collection

//User写入DataBase
type User struct {
	UUID  string `bson:"uuid"`
	Name  string `bson:"name"`
	Habit string `bson:"habit"`
}
