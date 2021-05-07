/*Please run entire script at once*/

declare @maxmonth varchar(10) = (Select max(format(purchasedate,'yyyy-MM')) from dbo.Receipts_fact a join dbo.Receipts_List_Attributes b on a.receiptid=b.receiptid where brandcode is not null)
declare @monthlast varchar(10) = (Select max(format(purchasedate,'yyyy-MM')) from dbo.Receipts_fact a join dbo.Receipts_List_Attributes b on a.receiptid=b.receiptid where brandcode is not null and format(purchasedate,'yyyy-MM')<>@maxmonth)

/*What are the top 5 brands by receipts scanned for most recent month?*/

select top 5 format(purchasedate,'yyyy-MM') purchasemonth, brandcode, count(distinct a.receiptid)receipts 
from dbo.Receipts_fact a
join dbo.Receipts_List_Attributes b on a.receiptid=b.receiptid
where brandcode is not null 
and format(purchasedate,'yyyy-MM')=@maxmonth
group by format(purchasedate,'yyyy-MM'), brandcode
order by receipts desc

/*How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
Assuming this is talking about comparing top 5 brands this month to top 5 brands last month*/

select top 5 format(purchasedate,'yyyy-MM') purchasemonth, brandcode, count(distinct a.receiptid)receipts 
from dbo.Receipts_fact a
join dbo.Receipts_List_Attributes b on a.receiptid=b.receiptid
where brandcode is not null 
and format(purchasedate,'yyyy-MM')=@monthlast
group by format(purchasedate,'yyyy-MM'), brandcode
order by receipts desc

/*When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
There is no 'Accepted' status so I used 'Finished' instead*/

 select rewardsreceiptstatus, avg(totalspent)avgSpend  
 from dbo.Receipts_Fact
 where rewardsreceiptstatus in ('FINISHED', 'rejected')
 group by rewardsreceiptstatus

 /*When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater??
There is no 'Accepted' status so I used 'Finished' instead*/

 select rewardsreceiptstatus, sum(purchaseditemcount)totalitems  
 from dbo.Receipts_Fact
 where rewardsreceiptstatus in ('FINISHED', 'rejected')
 group by rewardsreceiptstatus

/*Which brand has the most spend among users who were created within the past 6 months?*/

 select top 1 brandcode, sum(finalprice)finalprice from (
 select a.receiptid, max(brandcode)brandcode, sum(cast(finalprice as float))finalprice from dbo.Receipts_fact a
join dbo.Receipts_List_Attributes b on a.receiptid=b.receiptid
join dbo.dim_users c on a.userid=c.userid
where createddate>= dateadd(month, -6, getdate())
group by a.receiptid 
having max(brandcode) is not null)a
group by brandcode
order by finalprice desc

/*Which brand has the most transactions among users who were created within the past 6 months?*/

 select top 1 brandcode, sum(quantitypurchased)quantitypurchased from (
 select a.receiptid, max(brandcode)brandcode, sum(cast(quantitypurchased as float))quantitypurchased from dbo.Receipts_fact a
join dbo.Receipts_List_Attributes b on a.receiptid=b.receiptid
join dbo.dim_users c on a.userid=c.userid
where createddate>= dateadd(month, -6, getdate())
group by a.receiptid 
having max(brandcode) is not null)a
group by brandcode
order by quantitypurchased desc
