package main

import (
	"context"
	"log"
	"net"

	pb "storage/proto"
	"go.mongodb.org/mongo-driver/bson"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const (
	port = ":50051"
)

type server struct {
	pb.UnimplementedStorageServer
}

func (s *server) GetProfile(ctx context.Context, req *pb.GetProfileRequest) (*pb.GetProfileResponse, error) {
	reqUser := &User{
		UUID: req.GetUserUuid(),
	}
	log.Println("GetProfile function invoked")
	filter := bson.M{"uuid": reqUser.UUID}
	res := UserCollection.FindOne(ctx, filter)
	if err := res.Decode(reqUser); err != nil {
		log.Println("the user uuid is not found")
		return nil, status.Errorf(codes.NotFound, "the user uuid is not found")
	}
	response := &pb.GetProfileResponse{
		Name:  reqUser.Name,
		Habit: reqUser.Habit,
	}
	return response, nil
}

func (s *server) UpdateProfile(ctx context.Context, req *pb.UpdateProfileRequest) (*pb.UpdateProfileResponse, error) {
	log.Println("UpdateProfile function invoked")
	uuid := req.GetUserUuid()
	name := req.GetName()
	habit := req.GetHabit()

	reqUser := &User{
		UUID:  uuid,
	}

	//find the user
	filter := bson.M{"uuid": reqUser.UUID}
	res := UserCollection.FindOne(ctx, filter)
	if err := res.Decode(reqUser); err != nil { 
		//if not found, insert the user
		_, insertErr := UserCollection.InsertOne(ctx, reqUser) 
		if insertErr != nil {
			return nil, status.Errorf(codes.Internal, "Internal Error Occured while creating User %v\n", insertErr)
		}
	}

	//update the user
	update := bson.M{"$set": bson.M{"name": name, "habit": habit}}
	updateErr := UserCollection.FindOneAndUpdate(ctx, filter, update).Err()
	if updateErr != nil {
		return nil, status.Errorf(codes.Internal, "Internal Error Occured while updating User %v\n", updateErr)
	}

	return &pb.UpdateProfileResponse{
		Name:  name,
		Habit: habit,
	}, nil
}

func LaunchingServer(ctx context.Context) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	srv := grpc.NewServer()
	pb.RegisterStorageServer(srv, &server{})
	if err := srv.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}

	<-ctx.Done()

	srv.GracefulStop()
	return nil
}
