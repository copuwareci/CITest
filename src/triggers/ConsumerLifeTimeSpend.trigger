/*
 Calculate the Consumer Lifetime Spend.
*/

trigger ConsumerLifeTimeSpend on Ticket__c (after delete, after insert, after update)
    {
    //Set for unique Customer Ids   
    Set<Id> ConsumerIds = new Set<Id>();
    //Update List for the Customers
    list<Consumer__c> lstConsumertoUpdate = new list<Consumer__c>();
    
    //Get the ConsumerId from the Record.
    if(trigger.isInsert || trigger.isUpdate)
        {
        for(Ticket__c t : trigger.new)
            {
            if(t.Consumer__c != null)   
            ConsumerIds.add(t.Consumer__c);
            }
        }
    //Get the ConsumerId from the Record. 
    if(trigger.isDelete || trigger.isUpdate)
        {
        for(Ticket__c t : trigger.old)
            {
            if(t.Consumer__c != null)   
            ConsumerIds.add(t.Consumer__c);
            }
        }

    if(!ConsumerIds.isempty())
        {
        //Aggregate the sum of Purchased tickets for the Consumer.  
        list<AggregateResult> lstAR = new list<AggregateResult>();
        lstAR = [Select Consumer__c, Sum(Cost__c)LifeTimeSpend, Status__c from Ticket__c where Consumer__c IN:ConsumerIds GROUP BY Consumer__c, Status__c];
        for (AggregateResult ar: lstAR)
            {
            if(ar.get('Status__c') == 'Purchased')
                {   
                Consumer__c c = new Consumer__c(Id=String.valueOf(ar.get('Consumer__c')));
                c.Lifetime_Spend__c = double.valueOf(ar.get('LifeTimeSpend'));
                lstConsumertoUpdate.add(c);
                }
            if(!lstConsumertoUpdate.isempty())
                { 
                //Update the Consumers.
                update lstConsumertoUpdate;
                }
            }
        }
    }