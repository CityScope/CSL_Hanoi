/***
* Name: TestConnectionUDP
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model TestConnectionUDP
	

global {	

	int port <- 9877;
	string url <- "127.0.0.1";	
	init {
		write "After having launched this model, run the program UDPMouseLocationSender / UDPMouseLocationSender.pde with Processing 3. ";
		write "Processing 3 can be found here: https://processing.org/";
		write "Run the GAMA simulation, move the mouse on the gray small screen of Processing 3 and observe the move of the agent in GAMA" color: #red;
		
		create NetworkingAgent number: 1 {
		   do connect to: url protocol: "udp_server" port: port ;
		}		
	} 
}

species NetworkingAgent skills:[network] {
	
	
	reflex fetch when:has_more_message() {	
//		write length(mailbox);
		loop while:has_more_message()
		{
			message mes <- fetch_message();	
//			write mes;
			
 			list m <- string(mes.contents) split_with('[, ]');
// 			write mes.contents;
// 			write m;
// 			
// 			write length(string(res.contents));
			list<list<int>> scan_result <- [];
 			loop i from:0 to: length(m)-2 step: 2 {
 				scan_result <+ [int(m[i]),int(m[i+1])];
			}
 			write(scan_result);
 			write length(scan_result); 			
// 			write(length(m));
// 			scan_result <- []; 

		}
	}
}

experiment Server_testdd type: gui {}

