
/*Please run entire script at once*/

/* Issue 1: duplicates in the user data*/

 DECLARE @JSON VARCHAR(MAX)

SELECT 
@JSON = '[' + RIGHT(REPLACE(d.BulkColumn, '{"_id":', ',{"_id":'),LEN(REPLACE(d.BulkColumn, '{"_id":', ',{"_id":'))-1)+ ']'
FROM OPENROWSET 
(BULK 'C:\users.json', SINGLE_CLOB) d

declare @usersholding table (state varchar(3), active bit, role varchar(16), createdDate  nvarchar(max), _id nvarchar(max), lastLogin nvarchar(max) , signUpSource varchar(16), rownumber int) 

insert @usersholding
select *,  row_number() over (order by state)   
from   openjson (@json)
WITH (state varchar(3), active bit, role varchar(16), createdDate  nvarchar(max) AS JSON, _id nvarchar(max) AS JSON, lastLogin nvarchar(max) AS JSON , signUpSource varchar(16))    


select count(_id) records, count(distinct _id) distinct_records from @usersholding

/* Issue 2: expected to join from receipts to brand_dim on brandcode but this value is not unique in the brands file - should have brandid available in receipts file to join on*/

select brandcode, count(*) dupes from dbo.dim_brands
where isnull(brandcode,'')<>''
group by brandcode
having count(*)>1

/* Issue 3: many brandcodes are null or blank*/

select count(*) brands_with_no_code from dbo.dim_brands
where isnull(brandcode,'')<>''

/* Issue 4: most receipts have no brandcode information on items purchased and those that do are mostly from January*/


SELECT 
@JSON = '[' + RIGHT(REPLACE(d.BulkColumn, '{"_id":', ',{"_id":'),LEN(REPLACE(d.BulkColumn, '{"_id":', ',{"_id":'))-1)+ ']'
FROM OPENROWSET 
(BULK 'C:\receipts.json', SINGLE_CLOB) d

declare @receiptsholding table (receiptId varchar(64), bonusPointsEarned int, bonusPointsEarnedReason nvarchar(max), createDate  nvarchar(max) , dateScanned nvarchar(max),  finishedDate nvarchar(max), modifyDate nvarchar(max), pointsAwardedDate nvarchar(max), pointsEarned float, purchaseDate nvarchar(max), purchasedItemCount int, rewardsReceiptItemList nvarchar(max), rewardsReceiptStatus varchar(16), totalSpent float, userId varchar(32),  rownumber int) 



insert @receiptsholding 
select *,  row_number() over (order by _id)   
from   openjson (@json)
WITH (_id nvarchar(max) AS JSON, bonusPointsEarned int, bonusPointsEarnedReason nvarchar(max), createDate  nvarchar(max) as json,  dateScanned nvarchar(max) as json, finishedDate nvarchar(max) AS JSON, modifyDate nvarchar(max) AS JSON, pointsAwardedDate nvarchar(max) AS JSON, pointsEarned float, purchaseDate nvarchar(max) AS JSON , purchasedItemCount int, rewardsReceiptItemList nvarchar(max) as json, rewardsReceiptStatus varchar(16), totalSpent float, userId varchar(32))


select sum(case when rewardsReceiptItemList like '%brandcode%' then 1 else 0 end) has_brandcode, sum(case when rewardsReceiptItemList not like '%brandcode%' then 1 else 0 end) no_brandcode from @receiptsholding  

select distinct cast(purchasedate as date) purchasedate_for_items_with_brand_info
from dbo.Receipts_Fact a 
join dbo.Receipts_List_Attributes b on a.receiptid=b.receiptid  
where  brandcode is not null 
order by purchasedate_for_items_with_brand_info
