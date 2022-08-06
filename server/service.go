package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"sync"

	pb "storage/proto"

	"go.mongodb.org/mongo-driver/bson"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

const (
	port   = ":50051"
	header = "storage.app"
)

type ServerStreamClient struct {
	Stream pb.Storage_SubscribeServer //for streaming
	error  chan error
}

type BidiStreamClient struct {
	Stream pb.Storage_BidiStreamServer //for streaming
	error  chan error
}

type server struct {
	ServerStreamConnectionPool map[string]*ServerStreamClient //map[uuid]*Client
	ServerStreamBroadcastChan  chan *pb.ServerStreamResponse

	BidiStreamConnectionPool map[string]*BidiStreamClient //map[uuid]*Client
	BidiStreamBroadcastChan  chan *pb.BidiStreamResponse

	mutex sync.Mutex
	pb.UnimplementedStorageServer
}

func (s *server) getUUIDFromClientContext(ctx context.Context) (uuidAsToken string, ok bool) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok || len(md[header]) == 0 || len(md[header][0]) == 0 { //check if both key and value of header are empty
		return "", false
	}

	return md[header][0], true
}
func (s *server) addToConnectionPool(stream pb.Storage_BidiStreamServer, uuid string) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	//add to the connection pool
	connected := &BidiStreamClient{
		Stream: stream,
		error:  make(chan error),
	}
	s.BidiStreamConnectionPool[uuid] = connected
	log.Println("User added to BidiStream-ConnectionPool")

}

func (s *server) removedFromConnectionPool(uuid string) {
	s.mutex.Lock()
	defer s.mutex.Unlock()
	//remove the user from the ConnectionPool
	_, ok := s.BidiStreamConnectionPool[uuid]
	if ok {
		delete(s.BidiStreamConnectionPool, uuid)
		log.Printf("remove the user [%v] from connection pool \n", uuid)
	} else {
		log.Println("CloseStream error: removal user does not exists:", uuid)
	}
}

func (s *server) BidiStream(stream pb.Storage_BidiStreamServer) error {
	ctx := stream.Context()
	log.Println("BidiStream function invoked")
	identifiedUUID, ok := s.getUUIDFromClientContext(ctx) //requires client send its uuid as the metadata's value
	if !ok {
		return status.Error(codes.Unauthenticated, "Streaming error: uuid is missing as token header")
	}

	s.addToConnectionPool(stream, identifiedUUID)
	defer s.removedFromConnectionPool(identifiedUUID)

	for {
		in, err := stream.Recv()
		if err == io.EOF {
			return nil
		}
		if err != nil {
			log.Println("BidiStream error:", ctx.Err())
			return err
		}
		uuid := in.GetUserUuid()
		switch in.GetAction().(type) {
		case *pb.BidiStreamRequest_Login:
			log.Println("Login action invoked")
			login := &pb.BidiStreamResponse{
				BroadcastMessage: uuid + " login",
			}
			s.BidiStreamBroadcastChan <- login
		case *pb.BidiStreamRequest_Logout:
			log.Println("Logout action invoked")
			logout := &pb.BidiStreamResponse{
				BroadcastMessage: uuid + " logout",
			}
			s.BidiStreamBroadcastChan <- logout
		case *pb.BidiStreamRequest_Broadcast:
			log.Println("Broadcast action invoked")
			_, ok := s.BidiStreamConnectionPool[uuid]
			if !ok {
				return status.Errorf(codes.NotFound, "User did not login")
			}
			mes := in.GetBroadcast()
			br := &pb.BidiStreamResponse{
				BroadcastMessage: fmt.Sprintf("[%v]: %v", uuid, mes),
			}
			s.BidiStreamBroadcastChan <- br
		}
	}
}

func (s *server) Subscribe(req *pb.SubscribeRequest, stream pb.Storage_SubscribeServer) error {
	log.Println("Subscribe function invoked")

	uuid := req.GetUserUuid()
	//add to the connection pool
	connected := &ServerStreamClient{
		Stream: stream,
		error:  make(chan error),
	}
	s.ServerStreamConnectionPool[uuid] = connected

	sub := &pb.ServerStreamResponse{
		BroadcastMessage: uuid + " subscribed",
	}
	s.ServerStreamBroadcastChan <- sub
	return <-connected.error //block until the client disconnects
}

func (s *server) Unsubscribe(ctx context.Context, req *pb.UnsubscribeRequest) (*pb.UnsubscribeResponse, error) {
	log.Println("Unsubscribe function invoked")
	uuid := req.GetUserUuid()
	delete(s.ServerStreamConnectionPool, uuid)

	unsub := &pb.ServerStreamResponse{
		BroadcastMessage: uuid + " unsubscribed",
	}
	s.ServerStreamBroadcastChan <- unsub

	return &pb.UnsubscribeResponse{
		UnsubscribedMessage: uuid + " unsubscribed",
	}, nil
}

func (s *server) Greeting(ctx context.Context, req *pb.GreetingRequest) (*pb.Empty, error) {
	log.Println("Broadcast function invoked")
	uid := req.GetUserUuid()
	_, ok := s.ServerStreamConnectionPool[uid]
	if !ok {
		return nil, status.Errorf(codes.NotFound, "User did not subscribe")
	}
	mes := req.GetMessage()
	br := &pb.ServerStreamResponse{
		BroadcastMessage: fmt.Sprintf("[%v]: %v", uid, mes),
	}
	s.ServerStreamBroadcastChan <- br
	return &pb.Empty{}, nil
}

func (s *server) GetProfile(ctx context.Context, req *pb.GetProfileRequest) (*pb.GetProfileResponse, error) {
	reqUser := &User{
		UUID: req.GetUserUuid(),
	}
	log.Println("GetProfile function invoked")
	filter := bson.M{"uuid": reqUser.UUID}
	res := UserCollection.FindOne(ctx, filter)
	if err := res.Decode(reqUser); err != nil {
		log.Println("the user's uuid is not found")
		return nil, status.Errorf(codes.NotFound, "the user's uuid is not found")
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
		UUID: uuid,
	}

	//find the user
	filter := bson.M{"uuid": reqUser.UUID}
	res := UserCollection.FindOne(ctx, filter)
	if err := res.Decode(reqUser); err != nil {
		//if not found, insert the user
		_, insertErr := UserCollection.InsertOne(ctx, reqUser)
		if insertErr != nil {
			return nil, status.Errorf(codes.Internal, "Internal error occured while creating user %v\n", insertErr)
		}
	}

	//update the user
	update := bson.M{"$set": bson.M{"name": name, "habit": habit}}
	updateErr := UserCollection.FindOneAndUpdate(ctx, filter, update).Err()
	if updateErr != nil {
		return nil, status.Errorf(codes.Internal, "Internal error occured while updating user %v\n", updateErr)
	}

	return &pb.UpdateProfileResponse{
		Name:  name,
		Habit: habit,
	}, nil
}

func LaunchingServer() *server {
	return &server{
		ServerStreamConnectionPool: make(map[string]*ServerStreamClient),
		ServerStreamBroadcastChan:  make(chan *pb.ServerStreamResponse, 100),
		BidiStreamConnectionPool:   make(map[string]*BidiStreamClient),
		BidiStreamBroadcastChan:    make(chan *pb.BidiStreamResponse, 100),
	}
}
func (s *server) Run(ctx context.Context) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	srv := grpc.NewServer()
	pb.RegisterStorageServer(srv, s)

	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	go s.serverStreamBroadcasts()
	go s.bidiStreamBroadcasts()

	go func() {
		_ = srv.Serve(lis)
		cancel()
		log.Println("server stopped")
	}()

	<-ctx.Done()

	close(s.ServerStreamBroadcastChan)

	srv.GracefulStop()
	return nil
}

func (s *server) serverStreamBroadcasts() {
	for {
		res := <-s.ServerStreamBroadcastChan
		for clientUUID, conn := range s.ServerStreamConnectionPool {
			if conn.Stream == nil {
				continue
			} else {
				if c, ok := status.FromError(conn.Stream.Send(res)); ok {
					switch c.Code() {
					case codes.OK:
						log.Println("send msg to client", clientUUID)
					case codes.Canceled:
						log.Println("client canceled", clientUUID)
						conn.error <- errors.New("client canceled")
						delete(s.ServerStreamConnectionPool, clientUUID)
					case codes.Unavailable, codes.DeadlineExceeded:
						log.Println("client terminated connection", clientUUID)
						conn.error <- errors.New("client terminated connection")
						delete(s.ServerStreamConnectionPool, clientUUID)
					default:
						log.Println("failed to send to client", clientUUID)
					}
				}
			}
		}
	}
}

func (s *server) bidiStreamBroadcasts() {
	for {
		res := <-s.BidiStreamBroadcastChan
		for clientUUID, conn := range s.BidiStreamConnectionPool {
			if conn.Stream == nil {
				continue
			} else {
				if c, ok := status.FromError(conn.Stream.Send(res)); ok {
					switch c.Code() {
					case codes.OK:
						log.Println("send msg to client", clientUUID)
					case codes.Canceled:
						log.Println("client canceled", clientUUID)
						conn.error <- errors.New("client canceled")
						delete(s.ServerStreamConnectionPool, clientUUID)
					case codes.Unavailable, codes.DeadlineExceeded:
						log.Println("client terminated connection", clientUUID)
						conn.error <- errors.New("client terminated connection")
						delete(s.ServerStreamConnectionPool, clientUUID)
					default:
						log.Println("failed to send to client", clientUUID)
					}
				}
			}
		}
	}
}
