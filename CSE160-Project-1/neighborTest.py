from TestSim import TestSim

def main():
    # Get simulation ready to run.
    s = TestSim();

    # Before we do anything, lets simulate the network off.
    s.runTime(1);

    # Load the the layout of the network.
    s.loadTopo("long_line.topo");

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt");

    # Turn on all of the sensors.
    s.bootAll();

    # Add the main channels. These channels are declared in includes/channels.h
    #s.addChannel(s.COMMAND_CHANNEL);
    #s.addChannel(s.GENERAL_CHANNEL);
    #s.addChannel(s.FLOODING_CHANNEL);
    s.addChannel(s.NEIGHBOR_CHANNEL);

    # After sending a ping, simulate a little to prevent collision.
    s.runTime(1);
    #s.ping(1, 4, "Hello, World");
    #s.runTime(1);

    #s.ping(4, 1, "Hi!");
    s.runTime(550);
    #s.moteOff(4);
    #s.runTime(40);
    s.neighborDMP(7);
    s.runTime(40);

if __name__ == '__main__':
    main()
