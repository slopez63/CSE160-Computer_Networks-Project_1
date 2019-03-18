/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"
#include "../../includes/am_types.h"

configuration NodeC{
}
implementation {
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;

    Node -> MainC.Boot;

    Node.Receive -> GeneralReceive;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;


    //Created a list to keep track of packages received
    components new ListC(pack*, 64) as packListC;

    //list to keep track of neighbor nodes
    components new ListC(uint8_t, 64) as neighborListC;

    components new TimerMilliC() as myTimerC;



    Node.packList -> packListC;
    Node.neighborList -> neighborListC;
    Node.checkNeigh-> myTimerC;
}
