/*
Test Class for the ConsumerLifeTimeSpend Trigger
*/
@isTest
private class Test_ConsumerLifeTimeSpend
	{
    static testMethod void ConsumerLifeTimeSpend()
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
		
		system.runas(user)
			{
			Test.startTest();
				{
				//Insert Tickets.	
				list<Ticket__c> Tickets = new list<Ticket__c>();
				for(Seat__c s: Seats)
					{
					Ticket__c t = new Ticket__c();
					t.Performance__c = p.Id;
					t.Seat__c = s.Id;
					t.Cost__c  = 200;
					t.Status__c = 'Purchased';
					t.Consumer__c = c.Id;
					Tickets.add(t);
					}
				insert Tickets;	
				
				//Update Tickets to reserved.
				for(Ticket__c t: Tickets)
					{
					t.Status__c	= 'Reserved';
					}
				update Tickets;
				
				//Delete all the Tickets.
				delete Tickets;	
				}
    		}
 		}
	}