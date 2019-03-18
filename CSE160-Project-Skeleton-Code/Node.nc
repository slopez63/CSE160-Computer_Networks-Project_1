/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses interface List<pack*> as packList;
   uses interface List<uint8_t> as neighborList;
   uses interface Timer<TMilli> as checkNeigh;
}

implementation{
   pack sendPackage;
   pack* loopPackage;
   pack* replypkg;
   bool check;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   void printList();
   void printNeighList();
   bool hasbeenseen(pack* pkg);
   bool hasbeenseen2(pack* pkg2);
   void clearList();
   void clearList2();


   // Boot
   event void Boot.booted(){
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      call checkNeigh.startPeriodic(500);
      }else{
         // Retry until successful
         call AMControl.start();
      }

      dbg(NEIGHBOR_CHANNEL, "Started Neighbor Timer\n");
      
   }

   // Stop
   event void AMControl.stopDone(error_t err){}



   // Event Message Recieved
   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      
      uint8_t i, size;
      
      //dbg(GENERAL_CHANNEL, "Packet Received\n");

      // General check if correct type package
      if(len==sizeof(pack)){

         pack* myMsg=(pack*) payload;

         
         // Ping Protocol
         if(myMsg->protocol == PROTOCOL_PING){


            // Check if this is the package destination
            if(myMsg->dest == TOS_NODE_ID && hasbeenseen(myMsg) == FALSE){
               call packList.pushback(myMsg);
               
               dbg(FLOODING_CHANNEL, "Package Delivered and Acknoleged\n");   
               dbg(FLOODING_CHANNEL, "Package Payload: %s\n", myMsg->payload);


               makePack(&sendPackage, TOS_NODE_ID, myMsg->src, myMsg->TTL, PROTOCOL_PINGREPLY, 0, "REPLY", PACKET_MAX_PAYLOAD_SIZE);
               call Sender.send(sendPackage, myMsg->src);

               return msg;
            }


            // Check if this package had been received before
            if(hasbeenseen(myMsg) == FALSE){
               call packList.pushback(myMsg);

               dbg(FLOODING_CHANNEL, "Packet Fowarded\n");            
               makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL-1, PROTOCOL_PING, myMsg->seq + 1, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
               call Sender.send(sendPackage, myMsg->dest);

               //dbg(FLOODING_CHANNEL, "List %u Node:\n", TOS_NODE_ID);
               

               return msg;
            }
            

               // Otherwise ignore message
               dbg(FLOODING_CHANNEL, "Packet Ignored\n");
               return msg;

         }

         // Ping Reply Protocol
         if(myMsg->protocol == PROTOCOL_PINGREPLY){
            //dbg(FLOODING_CHANNEL, "asdasd Payload: %d\n", myMsg->dest);
            dbg(FLOODING_CHANNEL, "Reply Recieved\n");

              if(myMsg->dest == TOS_NODE_ID && hasbeenseen(myMsg) == FALSE){
                     call packList.pushback(myMsg);
                     dbg(FLOODING_CHANNEL, "Reply Recieved and Acknoleged\n");
                     dbg(FLOODING_CHANNEL, "SEQ %d\n", myMsg->seq);

                     return msg;
                  }

         if(hasbeenseen(myMsg) == FALSE){
               
                  call packList.pushback(myMsg);
                  dbg(FLOODING_CHANNEL, "Reply Fowarded\n");
                  
                  makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL-1, PROTOCOL_PINGREPLY, myMsg->seq +1, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
                  call Sender.send(sendPackage, myMsg->dest);
                  return msg;
                  }else{
                
                  dbg(FLOODING_CHANNEL, "Reply Ignored\n");
               }
                      
            
            return msg;

         }

   
         // Neighbor Protocol
         if(myMsg->protocol == PROTOCOL_NEIGHBOR){


            if(myMsg->TTL == 1 && hasbeenseen2(myMsg) == FALSE){
               call neighborList.pushback(myMsg->src);
               return msg;
            }else if(myMsg->TTL == 2){
               makePack(&sendPackage, TOS_NODE_ID, myMsg->src, myMsg->TTL-1, PROTOCOL_NEIGHBOR, myMsg->seq +1, "NEIGHBOR REPLY", PACKET_MAX_PAYLOAD_SIZE);
               call Sender.send(sendPackage, myMsg->src);
               return msg;

            }else{
               return msg;
            }

            return msg;
         }
         
         
         

      }

      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }



   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination);
      
 
   }

   event void CommandHandler.printNeighbors(){
uint8_t i, size, tmp;
      size = call neighborList.size();

      if(size == 0){
         dbg(NEIGHBOR_CHANNEL, "list is empty\n");
      }

      for(i = 0; i<size; i++){
         tmp = call neighborList.get(i);
         dbg(NEIGHBOR_CHANNEL, "This node is my neighbor:             %d\n", tmp);
      }

   }

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   event void checkNeigh.fired(){

      //dbg(NEIGHBOR_CHANNEL,"Time to check neighbors:    \n");
      
      //printList();
      //dbg(NEIGHBOR_CHANNEL, "\n");

      clearList2();

      makePack(&sendPackage, TOS_NODE_ID, 0, 2, PROTOCOL_NEIGHBOR, 0, "NEIGHBOR DISCOVERY", PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, 0);


   }

   
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }

   void printList(){
      uint8_t i, size, tmp;
      size = call neighborList.size();

      if(size == 0){
         dbg(NEIGHBOR_CHANNEL, "list is empty\n");
      }

      for(i = 0; i<size; i++){
         tmp = call neighborList.get(i);
         dbg(NEIGHBOR_CHANNEL, "This node is my neighbor:             %d\n", tmp);
      }
      
   }

   bool hasbeenseen(pack* pkg){

      uint8_t i, size;
      size = call packList.size();

      for(i = 0; i<size; i++){
         loopPackage = call packList.get(i);
         if((loopPackage->src == pkg->src || loopPackage->seq < pkg->seq ) && pkg->protocol == loopPackage->protocol && pkg->protocol == PROTOCOL_PING){
               return TRUE;
         }
         if((loopPackage->payload == pkg->payload) && pkg->protocol == loopPackage->protocol && pkg->protocol == PROTOCOL_PINGREPLY){
               return TRUE;
         }

          // if(loopPackage->protocol == pkg->protocol){
          //      if(loopPackage->payload == pkg->payload){
          //         //if(loopPackage->src == pkg->src){
          //            //if(loopPackage->seq > pkg->seq){

          //               return TRUE;
          //         //S}
          //      //}
          //   }
          // }
      }
      
      return FALSE;
   }

   bool hasbeenseen2(pack* pkg2){

      uint8_t i, size, tmp;
      size = call neighborList.size();

      for(i = 0; i<size; i++){
         tmp = call neighborList.get(i);
         if(tmp == pkg2->src){
            return TRUE;
         }
      }
      
      return FALSE;
   }

   void clearList(){

      uint8_t i, size;
      size = call packList.size();

      for(i = 0; i<size; i++){
         call packList.popback();
         
      }
      
   }

   void clearList2(){

      uint8_t i, size;
      size = call neighborList.size();

      for(i = 0; i<size; i++){
         call neighborList.popback();
         
      }
      
   }
}
