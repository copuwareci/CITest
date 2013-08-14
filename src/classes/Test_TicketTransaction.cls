/*
Test Class for TicketTransaction Class
*/

@isTest
private class Test_TicketTransaction 
	{
    static testMethod void Reserve()
    	{
		Profile up = [select Id from profile where name = '*UC-Ticket Sales Agent'];
  		User user = new User(alias = 'test', email='salesagent@uc.com',
			emailencodingkey='UTF-8', lastname='Sales Agent', languagelocalekey='en_US',
			localesidkey='en_US', profileid = up.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='salesagent@ucababana.com');
        insert user;	
    	
    	Consumer__c c = new Consumer__c();
    	c.Last_Name__c = 'Test Consumer';	
    	insert c;
    	
    	Venue__c v = new Venue__c();
    	v.Name = 'Arena Club';
    	insert v;
    	
    	Performance__c p = new Performance__c();
    	datetime startDatetime = Datetime.newInstance(2099, 20 , 12, 00, 00, 00);
    	p.Name = 'P1';
    	p.Start_DateTime__c = startDatetime;
    	p.Status__c = 'On Sale';
    	p.Type__c = 'Pop';
    	p.Venue__c = v.Id;
    	insert p;
    	
		list<Seat__c> Seats = new list<Seat__c>();
		for(Integer i=0; i<99; i++)
			{
			Seat__c s = new Seat__c();
			s.Name = 'Seat - '+i;
			s.Row__c = 'Row'+i;
			s.Section__c = 'Section';
			s.Seat_Number__c  = i;
			s.Venue__c = v.Id;
			Seats.add(s);
			}
		insert Seats;
		
		list<Ticket__c> Tickets = new list<Ticket__c>();
		for(Seat__c s: Seats)
			{
			Ticket__c t = new Ticket__c();
			t.Performance__c = p.Id;
			t.Seat__c = s.Id;
			t.Cost__c  = 200;
			Tickets.add(t);
			}
		insert Tickets;
		
		system.runas(user)
			{
			Test.startTest();
				{
				PageReference pageRef = Page.TicketSales;       
				pageRef.getParameters().put('ConsumerId' , c.Id);
				Test.setCurrentPageReference(pageRef);
				        
				ApexPages.StandardController controller = new ApexPages.StandardController(Tickets[0]);
				TicketTransaction sc = new TicketTransaction(controller);
				sc.PerformanceId = p.Id;
				sc.performanceDetails();
				sc.getConsumer();
				sc.getFutureHeldAmount();
				sc.getFuturePurchasesAmount();
				sc.getPerformanceTickets();
				sc.FindTickets();
				
				//Positive Test for the Reserved Ticket
				sc.getPerformanceTickets();
				sc.tTicketList[0].checked=true;
				sc.reserve();
				sc.next();
				sc.previous();
				sc.last();
				sc.first();
				Boolean testVariable;
                testVariable = sc.hasNext;
                testVariable = sc.hasPrevious;
                Integer pgNumber;
                pgNumber = sc.pageNumber;
                pgNumber = sc.TotalPages;
                
				//Negative Test for the Reserved Ticket to capture the Apex Messages
				sc.getPerformanceTickets();
				Tickets[0].Status__c = 'Reserved';
				update Tickets;
				sc.tTicketList[0].checked=true;
				sc.reserve();
				
				//No Tickets Selected
				sc.getPerformanceTickets();
				sc.tTicketList[0].checked=false;
				sc.reserve();
				
				Test.stopTest();
				}
    		}
    	}
    	
    static testMethod void Release()
    	{
		Profile up = [select Id from profile where name = '*UC-Ticket Sales Agent'];
  		User user = new User(alias = 'test', email='salesagent@uc.com',
			emailencodingkey='UTF-8', lastname='Sales Agent', languagelocalekey='en_US',
			localesidkey='en_US', profileid = up.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='salesagent@ucababana.com');
        insert user;	
    	
    	Consumer__c c = new Consumer__c();
    	c.Last_Name__c = 'Test Consumer';	
    	insert c;
    	
    	Venue__c v = new Venue__c();
    	v.Name = 'Arena Club';
    	insert v;
    	
    	Performance__c p = new Performance__c();
    	datetime startDatetime = Datetime.newInstance(2099, 20 , 12, 00, 00, 00);
    	p.Name = 'P1';
    	p.Start_DateTime__c = startDatetime;
    	p.Status__c = 'On Sale';
    	p.Type__c = 'Pop';
    	p.Venue__c = v.Id;
    	insert p;
    	
		list<Seat__c> Seats = new list<Seat__c>();
		for(Integer i=0; i<99; i++)
			{
			Seat__c s = new Seat__c();
			s.Name = 'Seat - '+i;
			s.Row__c = 'Row'+i;
			s.Section__c = 'Section';
			s.Seat_Number__c  = i;
			s.Venue__c = v.Id;
			Seats.add(s);
			}
		insert Seats;
		
		list<Ticket__c> Tickets = new list<Ticket__c>();
		for(Seat__c s: Seats)
			{
			Ticket__c t = new Ticket__c();
			t.Performance__c = p.Id;
			t.Seat__c = s.Id;
			t.Cost__c  = 200;
			Tickets.add(t);
			}
		insert Tickets;
		
		system.runas(user)
			{
			Test.startTest();
				{
				PageReference pageRef = Page.TicketSales;       
				pageRef.getParameters().put('ConsumerId' , c.Id);
				Test.setCurrentPageReference(pageRef);
				        
				ApexPages.StandardController controller = new ApexPages.StandardController(Tickets[0]);
				TicketTransaction sc = new TicketTransaction(controller);
				sc.PerformanceId = p.Id;
				sc.FindTickets();
				sc.getPerformanceTickets();
				
				//Positive Test for the Released Ticket
				sc.getPerformanceTickets();
				Tickets[0].Status__c = 'Reserved';
				Tickets[0].Consumer__c = c.Id;
				update Tickets;				
				sc.tTicketList[0].checked=true;
				sc.release();
				
				//Negative Test for the Released Ticket to capture the Apex Messages
				sc.getPerformanceTickets();
				Tickets[0].Status__c = '';
				update Tickets;
				sc.tTicketList[0].checked=true;
				sc.release();
				
				//No Tickets Selected
				sc.getPerformanceTickets();
				sc.tTicketList[0].checked=false;
				sc.release();
				
				Test.stopTest();
				}
    		}
    	}

    static testMethod void Purchase()
    	{
		Profile up = [select Id from profile where name = '*UC-Ticket Sales Agent'];
  		User user = new User(alias = 'test', email='salesagent@uc.com',
			emailencodingkey='UTF-8', lastname='Sales Agent', languagelocalekey='en_US',
			localesidkey='en_US', profileid = up.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='salesagent@ucababana.com');
        insert user;	
    	
    	Consumer__c c = new Consumer__c();
    	c.Last_Name__c = 'Test Consumer';	
    	insert c;
    	
    	Venue__c v = new Venue__c();
    	v.Name = 'Arena Club';
    	insert v;
    	
    	Performance__c p = new Performance__c();
    	datetime startDatetime = Datetime.newInstance(2099, 20 , 12, 00, 00, 00);
    	p.Name = 'P1';
    	p.Start_DateTime__c = startDatetime;
    	p.Status__c = 'On Sale';
    	p.Type__c = 'Pop';
    	p.Venue__c = v.Id;
    	insert p;
    	
		list<Seat__c> Seats = new list<Seat__c>();
		for(Integer i=0; i<99; i++)
			{
			Seat__c s = new Seat__c();
			s.Name = 'Seat - '+i;
			s.Row__c = 'Row'+i;
			s.Section__c = 'Section';
			s.Seat_Number__c  = i;
			s.Venue__c = v.Id;
			Seats.add(s);
			}
		insert Seats;
		
		list<Ticket__c> Tickets = new list<Ticket__c>();
		for(Seat__c s: Seats)
			{
			Ticket__c t = new Ticket__c();
			t.Performance__c = p.Id;
			t.Seat__c = s.Id;
			t.Cost__c  = 200;
			Tickets.add(t);
			}
		insert Tickets;
		
		system.runas(user)
			{
			Test.startTest();
				{
				PageReference pageRef = Page.TicketSales;       
				pageRef.getParameters().put('ConsumerId' , c.Id);
				Test.setCurrentPageReference(pageRef);
				        
				ApexPages.StandardController controller = new ApexPages.StandardController(Tickets[0]);
				TicketTransaction sc = new TicketTransaction(controller);
				sc.PerformanceId = p.Id;
				sc.FindTickets();
				sc.getPerformanceTickets();
				
				//Positive Test for the Purchased Ticket
				sc.getPerformanceTickets();
				sc.tTicketList[0].checked=true;
				sc.purchase();
				
				//Negative Test for the Purchased Ticket to capture the Apex Messages
				sc.getPerformanceTickets();
				Tickets[0].Status__c = 'Purchased';
				update Tickets;				
				sc.tTicketList[0].checked=true;
				sc.purchase();
				
				//No Tickets Selected
				sc.getPerformanceTickets();
				sc.tTicketList[0].checked=false;
				sc.purchase();
				
				Test.stopTest();
				}
    		}
    	}   
    	 	
    static testMethod void ReturnTickets()
    	{
		Profile up = [select Id from profile where name = '*UC-Ticket Sales Agent'];
  		User user = new User(alias = 'test', email='salesagent@uc.com',
			emailencodingkey='UTF-8', lastname='Sales Agent', languagelocalekey='en_US',
			localesidkey='en_US', profileid = up.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='salesagent@ucababana.com');
        insert user;	
    	
    	Consumer__c c = new Consumer__c();
    	c.Last_Name__c = 'Test Consumer';	
    	insert c;
    	
    	Venue__c v = new Venue__c();
    	v.Name = 'Arena Club';
    	insert v;
    	
    	Performance__c p = new Performance__c();
    	datetime startDatetime = Datetime.newInstance(2099, 20 , 12, 00, 00, 00);
    	p.Name = 'P1';
    	p.Start_DateTime__c = startDatetime;
    	p.Status__c = 'On Sale';
    	p.Type__c = 'Pop';
    	p.Venue__c = v.Id;
    	insert p;
    	
		list<Seat__c> Seats = new list<Seat__c>();
		for(Integer i=0; i<99; i++)
			{
			Seat__c s = new Seat__c();
			s.Name = 'Seat - '+i;
			s.Row__c = 'Row'+i;
			s.Section__c = 'Section';
			s.Seat_Number__c  = i;
			s.Venue__c = v.Id;
			Seats.add(s);
			}
		insert Seats;
		
		list<Ticket__c> Tickets = new list<Ticket__c>();
		for(Seat__c s: Seats)
			{
			Ticket__c t = new Ticket__c();
			t.Performance__c = p.Id;
			t.Seat__c = s.Id;
			t.Cost__c  = 200;
			Tickets.add(t);
			}
		insert Tickets;
		
		system.runas(user)
			{
			Test.startTest();
				{
				PageReference pageRef = Page.TicketSales;       
				pageRef.getParameters().put('ConsumerId' , c.Id);
				Test.setCurrentPageReference(pageRef);
				        
				ApexPages.StandardController controller = new ApexPages.StandardController(Tickets[0]);
				TicketTransaction sc = new TicketTransaction(controller);
				sc.PerformanceId = p.Id;
				sc.FindTickets();
				sc.getPerformanceTickets();
				
				//Positive Test for the Return Ticket
				sc.getPerformanceTickets();
				Tickets[0].Status__c = 'Purchased';
				Tickets[0].Consumer__c = c.Id;
				update Tickets;		
				sc.tTicketList[0].checked=true;
				sc.returnTickets();
				
				//Negative Test for the Return Ticket to capture the Apex Messages
				sc.getPerformanceTickets();			
				sc.tTicketList[0].checked=true;
				sc.returnTickets();
				
				//No Tickets Selected
				sc.getPerformanceTickets();
				sc.tTicketList[0].checked=false;
				sc.returnTickets();
				
				Test.stopTest();
				}
    		}
    	}  

    static testMethod void AuxillaryTests()
    	{
		Profile up = [select Id from profile where name = '*UC-Ticket Sales Agent'];
  		User user = new User(alias = 'test', email='salesagent@uc.com',
			emailencodingkey='UTF-8', lastname='Sales Agent', languagelocalekey='en_US',
			localesidkey='en_US', profileid = up.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='salesagent@ucababana.com');
        insert user;	
    	
    	Consumer__c c = new Consumer__c();
    	c.Last_Name__c = 'Test Consumer';	
    	insert c;
    	
    	Venue__c v = new Venue__c();
    	v.Name = 'Arena Club';
    	insert v;
    	
    	Performance__c p = new Performance__c();
    	datetime startDatetime = Datetime.newInstance(2099, 20 , 12, 00, 00, 00);
    	p.Name = 'P1';
    	p.Start_DateTime__c = startDatetime;
    	p.Status__c = 'On Sale';
    	p.Type__c = 'Pop';
    	p.Venue__c = v.Id;
    	insert p;
    	
		list<Seat__c> Seats = new list<Seat__c>();
		for(Integer i=0; i<99; i++)
			{
			Seat__c s = new Seat__c();
			s.Name = 'Seat - '+i;
			s.Row__c = 'Row'+i;
			s.Section__c = 'Section';
			s.Seat_Number__c  = i;
			s.Venue__c = v.Id;
			Seats.add(s);
			}
		insert Seats;
		
		list<Ticket__c> Tickets = new list<Ticket__c>();
		for(Seat__c s: Seats)
			{
			Ticket__c t = new Ticket__c();
			t.Performance__c = p.Id;
			t.Seat__c = s.Id;
			t.Cost__c  = 200;
			Tickets.add(t);
			}
		insert Tickets;

				Tickets[0].Status__c = 'Purchased';
				Tickets[0].Consumer__c = c.Id;
				update Tickets;
						
		system.runas(user)
			{
			Test.startTest();
				{
				PageReference pageRef = Page.TicketSales;       
				pageRef.getParameters().put('ConsumerId' , c.Id);
				Test.setCurrentPageReference(pageRef);

				ApexPages.StandardController controller = new ApexPages.StandardController(Tickets[0]);
				TicketTransaction sc = new TicketTransaction(controller);
				sc.PerformanceId = p.Id;	
				sc.getConsumerTickets();
				sc.tTicketList[0].checked=true;
				sc.getConsumerTickets();		
				sc.toggleSelection();
				sc.checklist();
				sc.backtoConsumer();
				Test.stopTest();
				}
    		}
    	}  
    	    	
	}