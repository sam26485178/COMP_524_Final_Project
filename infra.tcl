set val(chan)           Channel/WirelessChannel    ;#Channel Type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail		   ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                        ;# max packet in ifq
set val(nn)             10                         ;# number of mobilenodes
set val(rp)             DumbAgent                  ;# routing protocol
set val(x)		120
set val(y)		120

Mac/802_11 set dataRate_ 54Mb

#Phy/WirelessPhy set CSThresh_ 10.00e-12
#Phy/WirelessPhy set RXThresh_ 10.00e-11
#Phy/WirelessPhy set Pt_ 0.1
#Phy/WirelessPhy set Pt_ 7.214e-3

# Initialize Global Variables
set ns_		[new Simulator]
set tracefd     [open infra.tr w]
set namtrace [open infra.nam w]
$ns_ trace-all $tracefd
$ns_ use-newtrace
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)


# set up topography object
set topo       [new Topography]

$topo load_flatgrid $val(x) $val(y)

# Create God
create-god $val(nn)

# Create channel
set chan_1_ [new $val(chan)]


$ns_ node-config -adhocRouting $val(rp) \
		-llType $val(ll) \
		-macType $val(mac) \
		-ifqType $val(ifq) \
		-ifqLen $val(ifqlen) \
		-antType $val(ant) \
		-propType $val(prop) \
		-phyType $val(netif) \
		-topoInstance $topo \
		-agentTrace OFF \
		-routerTrace OFF \
		-macTrace ON \
		-movementTrace ON \
		-channel $chan_1_


      for {set i 0} {$i < [expr $val(nn)]} {incr i} {
                  set node_($i) [$ns_ node]
		
                $node_($i) random-motion 0              ;# disable random motion
  		set mac_($i) [$node_($i) getMac 0]
 

      		$mac_($i) set RTSThreshold_ 3000
		
		#$node_($i) set X_ $i
		#$node_($i) set X_ [expr $i*10]
  		#$node_($i) set Y_ 0       ;# Horizontal arrangement of nodes
  		#$node_($i) set Z_ 0.0


	    $node_($i) set X_ [expr rand()*120]
	    $node_($i) set Y_ [expr rand()*120]
	    $node_($i) set Z_ 0

	    $ns_ initial_node_pos $node_($i) 3
		
	}
	
	
$node_(0) set X_ 50
$node_(0) set Y_ 20       ;# Horizontal arrangement of nodes
$node_(0) set Z_ 0.0





#Set Node 0 and Node $val(nn) as the APs. Thus the APs are the ends of the horizontal line. Each STA receives different power levels.


set AP_ADDR1 [$mac_(0) id]
$mac_(0) ap $AP_ADDR1
#set AP_ADDR2 [$mac_([expr $val(nn) - 1]) id]
#$mac_([expr $val(nn) - 1]) ap $AP_ADDR2

#$mac_([expr $val(nn) - 1]) set BeaconInterval_ 0.2


#$mac_(1) ScanType ACTIVE

for {set i 1} {$i < [expr $val(nn) - 0]} {incr i} {
	$mac_($i) ScanType PASSIVE	;#Passive
}


#$ns_ at 1.0 "$mac_(2) ScanType ACTIVE"

Application/Traffic/CBR set packetSize_ 1500
Application/Traffic/CBR set rate_ 1Mb
#Application/Traffic/CBR set rate_ 256Kb


for {set i 1} {$i < [expr $val(nn) - 0]} {incr i} {
	set udp1($i) [new Agent/UDP]

	$ns_ attach-agent $node_($i) $udp1($i)
	set cbr1($i) [new Application/Traffic/CBR]
	$cbr1($i) attach-agent $udp1($i)
	$cbr1($i) set random_ false

	set base0($i) [new Agent/Null]
	$ns_ attach-agent $node_($i) $base0($i)

}

for {set i 1} {$i < [expr $val(nn) - 1]} {incr i} {

	$ns_ connect $udp1($i) $base0([expr $i + 1])

}

$ns_ connect $udp1([expr $val(nn) - 1]) $base0(1)

for {set i 1} {$i < [expr $val(nn) - 0]} {incr i} {
	$ns_ at 2.0 "$cbr1($i) start"
}


#set base0 [new Agent/Null]

#$ns_ attach-agent $node_(1) $base0
#
#set base1 [new Agent/Null]

#$ns_ attach-agent $node_(3) $base1

#$ns_ connect $udp1(3) $base0
#$ns_ connect $udp1(5) $base1

#$ns_ connect $udp1(3) $base0
#$ns_ connect $udp1(1) $base1



#$ns_ at 2.0 "$cbr1(3) start"
#$ns_ at 2.0 "$cbr1(1) start"

#$ns_ at 4.0 "$cbr1(5) start"

#$ns_ at 10.0 "$node_(4) setdest 300.0 1.0 30.0"

$ns_ at 20.0 "stop"
$ns_ at 20.0 "puts \"NS EXITING...\" ; $ns_ halt"

proc stop {} {
    global ns_ tracefd namtrace udp1 dataRate_
    $ns_ flush-trace
    close $tracefd
    close $namtrace
    exit 0
}

puts "Starting Simulation..."

#exec awk -f Throughput.awk infra.tr > Throughput.tr &

$ns_ run

