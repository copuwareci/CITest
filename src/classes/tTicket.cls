//Wrapper Class for the TicketTransaction Class.

public class tTicket 
    {
    public Boolean checked {get; set;}
    public Ticket__c ticket {get; set;} 

    //Contructor method. Set the selected value to false
    public tTicket(Ticket__c t)
        {
        ticket = t;
        checked = false;
        }

    //Contructor method. Set the selected value to true
    public tTicket(Ticket__c t,string s)
        {
        ticket = t;
        checked = true;
        }
    }