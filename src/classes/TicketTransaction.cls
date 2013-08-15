/*
//Controller for the Page - TicketSales. Modified

Assumptions - 

1. Used the StandardSetController for pagination to save on extra queries and Query Rows.
2. Used Set of List to collect all the selected records by the Ticket Agent and to display the same as checked.
3. Available Ticketes are tickets which are not "Reserved or Purchased by another Consumer" Refunded Tickets are termed as "Available"
4. Add the Loading component on Page, but still its a partial refresh of the page only.

Reserve - 
	Only Tickets with '' and 'Refunded' Status can be Reserved.
	
Release - 
	Only Tickets with 'Reserved' Status can be Released.	
	
Purchase - 
	Only Tickets with 'Reserved' or '' Status can be Purchased.	
	
Refund - 
	Only Tickets with 'Purchased' Status can be Refunded.	

*/

public with sharing class TicketTransaction 
    {
    //Status set for Tickets and Performance
    private set<string> statusSet = new Set<String>{'Reserved', 'Purchased'};
    private set<string> PerformanceStatusSet = new Set<String>{'On Sale'};
    
    //Set of tickets, selected by the User
    private set<Ticket__c> selectedTickets;
    
    //Our collection of the class/wrapper tTicket
    public list<tTicket> tTicketList {get;set;}
    
    //Boolean variable to capture the page actions.
    public boolean  performanceSelected {get;set;}
    public boolean  bError {get;set;}
    
    //Variable to capture the User Future Purchase Amount and Future Held Amount
    public decimal TotalFuturePurchaseAmount {get;set;}
    public decimal TotalFutureHeldAmount {get;set;}

    // Performance filter and Start datetime variables.
    public Performance__c selectedPerformance { get; set; }
    public string PerformanceId;
    public datetime dPerformcanceDateTime;
    public string sformateddate  {get;set;}
    
    private final Ticket__c tckt; 
    
    //Set the page size for Pagination.
    private integer size = 10;
    
    //Tickets final list for the update.
    public list<Ticket__c> finalList = new list<Ticket__c>();
    
    //Query string to get the default list of reserved and purchased tickets where the performance date/time is >= today.
    public string QueryString  = 'Select Id, Name, Performance__c, Performance__r.Venue__r.Name, Seat__c, Seat__r.Row__c, Seat__r.Seat_Number__c, Cost__c, Status__c, Consumer__c FROM Ticket__c where Consumer__c =: ConsumerId and Performance__r.Start_DateTime__c >= Today and Status__c IN : statusSet order by Performance__c';
    
    //Salesforce recordid for the consumer.
    private Id ConsumerId = ApexPages.currentPage().getParameters().get('ConsumerId');
    
    //Standardsetcontroller for the pagiantion
    public ApexPages.Standardsetcontroller standardSetCon {get;set;}
    
    
    //Constructor
    public TicketTransaction(ApexPages.StandardController stdController)
        {
        this.tckt = (Ticket__c)stdController.getRecord();   
        tTicketList = new List<tTicket>();
        selectedTickets = new set<Ticket__c>();
        updateStandardSetController();
        }

    //Get the Consumer Info.            
    public Consumer__c consumer {set;}
    public Consumer__c getConsumer()
        {
        return [select Id, Name, First_Name__c, Last_Name__c 
            from Consumer__c where Id =: ConsumerId];
        }
            
    //Method to get the Total of future purchase amount for the consumer.
    public decimal getFuturePurchasesAmount()
        {   
        list<AggregateResult> lstAR = new list<AggregateResult>();
        //Aggregate query to sum the total cost for future purchased tickets.
        lstAR = [Select Sum(Cost__c)TotalFuturePurchases from Ticket__c where 
            Consumer__c =: ConsumerId and Performance__r.Start_DateTime__c >= Today and Status__c = 'Purchased'];

        for (AggregateResult ar: lstAR)
            {
            TotalFuturePurchaseAmount = (Decimal)ar.get('TotalFuturePurchases');
            }
        return TotalFuturePurchaseAmount;
        }

    //Method to get the Total of future held/reserved amount for the consumer.
    public decimal getFutureHeldAmount()
        {
        list<AggregateResult> lstAR = new list<AggregateResult>();
        //Aggregate query to sum the total cost for future held tickets.
        lstAR = [Select Sum(Cost__c)TotalFutureHeld from Ticket__c where 
            Consumer__c =: ConsumerId and Performance__r.Start_DateTime__c >= Today and Status__c = 'Reserved'];

        for (AggregateResult ar: lstAR)  
            {
            TotalFutureHeldAmount = (Decimal)ar.get('TotalFutureHeld');
            }
        return TotalFutureHeldAmount;
        }
    
    //Page method to find the tickets based on the user selected performance.   
    public PageReference FindTickets()
        {
        //set the boolean value to true once the findTickets commandbutton clicked. 
        performanceSelected = true; 
        PerformanceId = tckt.Performance__c; 
        /*
        Set the Query string to Query the Tickets alsong with the Seat and Venue Info
        //Refunded Ticketed woud also show as they would be termed as available.
        Conditions - (((Consumer__c = ConsumerId and Status = Reserved or Purchased) OR (Status != Reserved or Purchased or Refunded)) AND Preformance Datetime >= Today AND Performance Status = "On Sales")
        */
        QueryString = 'Select Id, Name, Performance__c, Performance__r.Venue__r.Name, Seat__c, Seat__r.Row__c, Seat__r.Seat_Number__c, Cost__c, Status__c, Consumer__c FROM Ticket__c where Performance__r.Start_DateTime__c >= Today and Performance__c =:PerformanceId and ((Consumer__c =: ConsumerId and Status__c IN :StatusSet) or Status__c NOT IN :StatusSet)  and Performance__r.Status__c IN :performanceStatusSet order by Seat__r.Row__c, Seat__r.Seat_Number__c ASC';
        //Clear all the Lists and Sets.
        clearList();
        return null;
        }

    //Instantiate the StandardSetController from a query locator
    public void updateStandardSetController()
        {   
        standardSetCon = new ApexPages.StandardSetController(Database.getQueryLocator(QueryString));
        //set the page size to 10
        standardSetCon .setPageSize(size);
        }
    
    //Consumers purchased and reserved tickets for the future shows
    public List<tTicket> getConsumerTickets()
        {
        updateSelectedTickets();
        tTicketList = new List<tTicket>();
        //get the records for the StandardSetController
        List<Ticket__c> tickets = standardSetCon.getRecords();
        for (Ticket__c t: tickets)
            {
            //check the records if already exsist in the SelectedTicket set.    
            if(selectedTickets.contains(t))
                tTicketList.add(new tTicket(t,'true'));
            else
                tTicketList.add(new tTicket(t));
            }       
        return tTicketList;
        }
    
    //Tickets for selected performance. 
    public List<tTicket> getPerformanceTickets()
        {
        updateSelectedTickets();
        tTicketList = new List<tTicket>();
        //get the records for the StandardSetController
        List<Ticket__c> tickets = standardSetCon.getRecords();
        system.debug('Tickets - '+tickets);
        for (Ticket__c t: tickets)
            {
            //check the records if already exsist in the SelectedTicket set.                    
            if(selectedTickets.contains(t))
                tTicketList.add(new tTicket(t,'true'));
            else
                tTicketList.add(new tTicket(t));
            }
        return tTicketList;
        }

    //Reserve the selected tickets
    public void reserve()
        {
        finalList.clear();
        bError = false; 
        updateSelectedTickets();
        if(!selectedTickets.isEmpty())
            {
            //Query the selected tickets    
            for (Ticket__c t : [Select Id, Name, Status__c, Consumer__c, Seat__r.Row__c, Seat__r.Seat_Number__c, Seat__r.Section__c, Seat__r.Venue__r.Name from Ticket__c where Id IN:selectedTickets]) 
                {
                //If tickets already purchased or reserved  
                if(t.Status__c == 'Purchased' || t.Status__c == 'Reserved')
                    {
                    bError = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Some tickets already held or purchased:'));
                    ApexPages.Message msg = new ApexPages.Message(Apexpages.Severity.WARNING, 'Section:' +t.Seat__r.Section__c+ ', Row:' +t.Seat__r.Row__c+ ', Seat Number:' +t.Seat__r.Seat_Number__c+ ', Venue:' +t.Seat__r.Venue__r.Name+ ', Status:' +t.Status__c);
                    ApexPages.addMessage(msg);
                    }
                else
                    {
                    Ticket__c ticket = new Ticket__c(Id = t.Id);
                    ticket.Status__c = 'Reserved';
                    ticket.Consumer__c = ConsumerId;
                    //Add the tickets to the finallist for the update
                    finalList.add(ticket);
                    }
                selectedTickets.clear();
                }
            
            if(!finalList.isempty() && !bError)
                {
                //Update the list of tickets    
                update finallist;
                clearList();
                }
            }
        //No tickets selected   
        else    
            {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'No Tickets Selected');
            ApexPages.addmessage(myMsg);                
            }
        }
    
    //Release the selected tickets  
    public void release()
        {
        finalList.clear();
        bError = false; 
        updateSelectedTickets();
        if(!selectedTickets.isEmpty())
            {
            //Query the selected tickets        
            for (Ticket__c t : [Select Id, Name, Status__c, Consumer__c, Seat__r.Row__c, Seat__r.Seat_Number__c, Seat__r.Section__c, Seat__r.Venue__r.Name from Ticket__c where Id IN:selectedTickets]) 
                {
                System.debug('Status - '+t.Status__c);
                System.debug('Consumer - '+t.Consumer__c);
                System.debug('Consumer Id - '+ConsumerId);      
                if(t.Status__c != 'Reserved' || t.Consumer__c != ConsumerId)
                    {
                    bError = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Some tickets are not Reserved'));
                    ApexPages.Message msg = new ApexPages.Message(Apexpages.Severity.WARNING, 'Section:' +t.Seat__r.Section__c+ ', Row:' +t.Seat__r.Row__c+ ', Seat Number:' +t.Seat__r.Seat_Number__c+ ', Venue:' +t.Seat__r.Venue__r.Name+ ', Status:' +t.Status__c);
                    ApexPages.addMessage(msg);
                    }
                else
                    {
                    Ticket__c ticket = new Ticket__c(Id = t.Id);
                    ticket.Status__c = '';
                    ticket.Consumer__c = null;
                    //Add the tickets to the finallist for the update
                    finalList.add(ticket);
                    }
                selectedTickets.clear();
                }
            
            if(!finalList.isempty() && !bError)
                {
                //Update the list of tickets    
                update finallist;
                clearList();
                }
            }
        //No tickets selected   
        else    
            {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'No Tickets Selected');
            ApexPages.addmessage(myMsg);                
            }
        }
    
    //Purchase the selected tickets.    
    public void purchase()
        {
        finalList.clear();
        bError = false; 
        updateSelectedTickets();
        if(!selectedTickets.isEmpty())
            {
            //Query the selected tickets        
            for (Ticket__c t : [Select Id, Name, Status__c, Consumer__c, Seat__r.Row__c, Seat__r.Seat_Number__c, Seat__r.Section__c, Seat__r.Venue__r.Name from Ticket__c where Id IN:selectedTickets]) 
                {
                if(t.Status__c == 'Purchased' || (t.Consumer__c != ConsumerId && (t.Status__c == 'Purchased' || t.Status__c == 'Reserved')))
                    {
                    bError = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Some tickets already purchased:'));
                    ApexPages.Message msg = new ApexPages.Message(Apexpages.Severity.WARNING, 'Section:' +t.Seat__r.Section__c+ ', Row:' +t.Seat__r.Row__c+ ', Seat Number:' +t.Seat__r.Seat_Number__c+ ', Venue:' +t.Seat__r.Venue__r.Name+ ', Status:' +t.Status__c);
                    ApexPages.addMessage(msg);
                    }
                else
                    {
                    Ticket__c ticket = new Ticket__c(Id = t.Id);
                    ticket.Status__c = 'Purchased';
                    ticket.Consumer__c = ConsumerId;
                    //Add the tickets to the finallist for the update
                    finalList.add(ticket);
                    }
                selectedTickets.clear();
                }
            
            if(!finalList.isempty() && !bError)
                {
                //Update the list of tickets    
                update finallist;
                clearList();
                }
            }
        //No tickets selected   
        else    
            {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'No Tickets Selected');
            ApexPages.addmessage(myMsg);                
            }
        }
    
    //Return the selected tickets.
    public void returntickets()
        {
        finalList.clear();
        bError = false; 
        updateSelectedTickets();
        if(!selectedTickets.isEmpty())
            {
            //Query the selected tickets        
            for (Ticket__c t : [Select Id, Name, Status__c, Consumer__c, Seat__r.Row__c, Seat__r.Seat_Number__c, Seat__r.Section__c, Seat__r.Venue__r.Name from Ticket__c where Id IN:selectedTickets]) 
                {
                if(t.Status__c != 'Purchased' || t.Consumer__c != ConsumerId)
                    {
                    bError = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Ticket is not purchased:'));
                    ApexPages.Message msg = new ApexPages.Message(Apexpages.Severity.WARNING, 'Section:' +t.Seat__r.Section__c+ ', Row:' +t.Seat__r.Row__c+ ', Seat Number:' +t.Seat__r.Seat_Number__c+ ', Venue:' +t.Seat__r.Venue__r.Name+ ', Status:' +t.Status__c);
                    ApexPages.addMessage(msg);
                    }
                else
                    {
                    Ticket__c ticket = new Ticket__c(Id = t.Id);
                    ticket.Status__c = 'Refunded';
                    ticket.Consumer__c = null;
                    //Add the tickets to the finallist for the update
                    finalList.add(ticket);
                    }
                selectedTickets.clear();
                }
            
            if(!finalList.isempty() && !bError)
                {
                //Update the list of tickets    
                update finallist;
                clearList();

                }
            }
        //No tickets selected   
        else    
            {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'No Tickets Selected');
            ApexPages.addmessage(myMsg);                
            }
        }
    
    // Returns the PageReference of the Consumer.
    public PageReference backtoconsumer()
        {
        PageReference reference = new PageReference('/'+ConsumerId);
        reference.setRedirect(true);
        return reference;
        }
    
    //Start Date/Time   of the selected Perforance
    public void performanceDetails()
        {
        try
            {
            selectedPerformance = [Select Id, Name, Start_DateTime__c from Performance__c Where Id = :tckt.Performance__c];
            dPerformcanceDateTime = selectedPerformance.Start_DateTime__c;
            sformateddate = dPerformcanceDateTime.format();
            }
        catch(Exception e)
            {
            //User just cleared the lookup box. and thus the above query will not have records. 
            }
        }
    
    //Method to the update the selected tickets set based on the user selected. 
    private void updateSelectedTickets()
        {
        for(tTicket tT:tTicketList)
            {
            if(tT.checked)
                selectedTickets.add(tT.ticket);
           else
                {
                if(selectedTickets.contains(tT.ticket))
                    selectedTickets.remove(tT.ticket);
                }
            }
        }


    //Select all method for the "Select All" checkbox
    public boolean selectall
        {
        get { selectall = checklist(); return selectall; } set;
        }

    //Toggle function for select all checkbox.
    public void toggleSelection()
        {
        boolean temp = !selectall;
        for(tTicket item: tTicketList)
            {
            item.checked = temp;
            }
        }

    //Check if all the checkboxed are checked.
    public boolean checklist()
        {
        boolean allchecked = true;
        for(tTicket item: tTicketList)
            {
            allchecked = allchecked && item.checked;
            }
        return allchecked;
        }

    //Clear all the Lists and Sets.
    public void clearList()
        {
        finalList.clear();
        selectedTickets.clear();
        tTicketList.clear();
        updateStandardSetController();
        bError = false;
        }
            
    // indicates whether there are more records after the current page set.    
    public Boolean hasNext
        {
        get {
            return standardSetCon.getHasNext();
            }
        set;
        }
    
    // indicates whether there are more records before the current page set.    
    public Boolean hasPrevious
        {
        get {
            return standardSetCon.getHasPrevious();
            }
        set;
        }
  
    // returns the page number of the current page set
    public Integer pageNumber
        {
        get {
            return standardSetCon.getPageNumber();
        }
        set;
        }
  
    // returns the first page of records
    public void first()
        {
        standardSetCon.first();
        }
  
    // returns the last page of records
    public void last()
        {
        standardSetCon.last();
        }
        
    // returns the previous page of records
    public void previous()
        {
        standardSetCon.previous();
        }
  
    // returns the next page of records
    public void next()
        {
        standardSetCon.next();
        }
    
    // returns the total numbe of pages
    public Integer TotalPages
        {
        get
            {   
            if (math.mod(standardSetCon.getResultSize(), size) > 0)
                {
                return standardSetCon.getResultSize()/size + 1;
                } 
            else
                {
                return (standardSetCon.getResultSize()/size);
                }
            }
            set;
        }   
    }