package main

import (
	"context"
	"log"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/mongo/readpref"
)

func main() {
	log.Println("Connecting MongoDB...")

	mctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	//for docker-compose
	log.Println("get MongoDB URI: ", os.Getenv("MONGODB_URI"))
	clientOpts := options.Client().ApplyURI(os.Getenv("MONGODB_URI")) //MongoDB port
	client, err := mongo.Connect(mctx, clientOpts)

	//for localhost
	//client, err := mongo.Connect(mctx, options.Client().ApplyURI("mongodb://localhost:27017"))

	if err != nil {
		log.Fatal("Could not connect to MongoDB: \n", err.Error())
	}

	defer func() {
		if err = client.Disconnect(mctx); err != nil {
			panic(err)
		}
	}()

	err = client.Ping(mctx, readpref.Primary()) //Calling Connect() does not block for server discovery. If you wish to know if a MongoDB server has been found and connected to, use the Ping() method.
	if err != nil {
		log.Fatal("Could not ping to MongoDB: \n", err.Error())
	}

	projectjDatabase := client.Database("storage")
	UserCollection = projectjDatabase.Collection("user")
	log.Println("MongoDB is ready.")

	ctx := context.Background()
	LaunchingServer().Run(ctx)
}
