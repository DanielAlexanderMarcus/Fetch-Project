/*
This script populates the tables for our data warehouse directly from the sample json files.  
Please create the 4 tables below before running for the first time. 
It is assumed that the raw json files are located directly in the C drive.  
The script may take a few minutes to complete.

create table dbo.Dim_Users  (state varchar(3), active bit, role varchar(16), createdDate  datetime, userId nvarchar(max), lastLogin datetime , signUpSource varchar(16)) 
create table dbo.Dim_Brands  (brandId varchar(64), barcode varchar(32), brandCode varchar(255), category  varchar(32), categoryCode varchar(64),  topBrand bit, name varchar(255), CPGRef varchar(16), CPGId varchar(32)) 
create table dbo.Receipts_Fact (receiptId varchar(64), bonusPointsEarned int, bonusPointsEarnedReason nvarchar(max), createDate datetime, dateScanned datetime,  finishedDate datetime, modifyDate datetime, pointsAwardedDate datetime, pointsEarned float, purchaseDate datetime, purchasedItemCount int, rewardsReceiptStatus varchar(16), totalSpent float, userId varchar(32)) 
create table dbo.Receipts_List_Name_Value (receiptId varchar(64), name nvarchar(255), value nvarchar(max)) 
*/
 

truncate table dbo.Dim_Users 
truncate table dbo.Dim_Brands 
truncate table dbo.Receipts_Fact 
truncate table dbo.Receipts_List_Name_Value 
 
 /*Pull in raw users data from json file*/

declare @temp table(brandid varchar(64), CPGRef varchar(64), CPGId varchar(64))

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


declare @iterator int
declare @jsoncreatedDate varchar(max)
declare @json_id varchar(max)
declare @jsonlastlogin varchar(max)

select @iterator = max(rownumber) from @usersholding
declare @users table (state varchar(3), active bit, role varchar(16), createdDate  datetime, userId nvarchar(max), lastLogin datetime , signUpSource varchar(16)) 

while @iterator>0 begin

select @jsoncreatedDate = createdDate,  @json_id=_id, @jsonlastlogin=lastLogin
from @usersholding
where rownumber=@iterator


insert @users

select state, active, role, DATEADD(S, CONVERT(int,LEFT(createdDate, 10)), '1970-01-01'),json_id, DATEADD(S, CONVERT(int,LEFT(jsonlastlogin, 10)), '1970-01-01'), signupsource from(
select state, active, role, 
(select value from openjson(@jsoncreatedDate)) createdDate,
(select value from openjson(@json_id))json_id,
(select value from openjson(@jsonlastlogin)) jsonlastlogin,
signupsource from @usersholding where rownumber=@iterator)a

set @iterator=@iterator-1 
end


 /*Dedupe Users File*/

insert dbo.Dim_Users 
select distinct * from @users


 /*Pull in raw brands data from json file*/

SELECT 
@JSON = '[' + RIGHT(REPLACE(d.BulkColumn, '{"_id":', ',{"_id":'),LEN(REPLACE(d.BulkColumn, '{"_id":', ',{"_id":'))-1)+ ']'
FROM OPENROWSET 
(BULK 'C:\brands.json', SINGLE_CLOB) d

declare @brandsholding table (brandId varchar(64), barcode varchar(32), brandCode varchar(255), category  varchar(32), categoryCode varchar(64), cpgId varchar(255), topBrand bit, name varchar(255), rownumber int) 


insert @brandsholding 
select *,  row_number() over (order by barcode)   
from   openjson (@json)
WITH (_id nvarchar(max) AS JSON, barcode varchar(32), brandCode varchar(255), category  varchar(32), categoryCode varchar(64), cpg nvarchar(max) AS JSON, topBrand bit, name varchar(255))   


declare @jsoncpgid varchar(max)

select @iterator = max(rownumber) from @brandsholding

while @iterator>0 begin

select @jsoncpgid = cpgId,  @json_id=brandid 
from @brandsholding
where rownumber=@iterator


insert @temp
select (select value from openjson(@json_id)), max([$ref]) cpgRef,max([$id])cpgId from (
select * from openjson(@jsoncpgid)) a
pivot (max(value) for [key] in ([$ref],[$id])) b

select @jsoncpgid = cpgid from @temp

insert dbo.Dim_Brands 

select (select value from openjson(a.brandid))brandid, barcode, brandCode, category, categorycode, topbrand, name,  b.cpgref, (select value from openjson(@jsoncpgid)) cpgId from @brandsholding a
left join @temp b on (select value from openjson(a.brandid))=b.brandid
where rownumber=@iterator
 

delete @temp


set @iterator=@iterator-1 
end


 /*Pull in raw receipts data from json file*/

SELECT 
@JSON = '[' + RIGHT(REPLACE(d.BulkColumn, '{"_id":', ',{"_id":'),LEN(REPLACE(d.BulkColumn, '{"_id":', ',{"_id":'))-1)+ ']'
FROM OPENROWSET 
(BULK 'C:\receipts.json', SINGLE_CLOB) d

declare @receiptsholding table (receiptId varchar(64), bonusPointsEarned int, bonusPointsEarnedReason nvarchar(max), createDate  nvarchar(max) , dateScanned nvarchar(max),  finishedDate nvarchar(max), modifyDate nvarchar(max), pointsAwardedDate nvarchar(max), pointsEarned float, purchaseDate nvarchar(max), purchasedItemCount int, rewardsReceiptItemList nvarchar(max), rewardsReceiptStatus varchar(16), totalSpent float, userId varchar(32),  rownumber int) 



insert @receiptsholding 
select *,  row_number() over (order by _id)   
from   openjson (@json)
WITH (_id nvarchar(max) AS JSON, bonusPointsEarned int, bonusPointsEarnedReason nvarchar(max), createDate  nvarchar(max) as json,  dateScanned nvarchar(max) as json, finishedDate nvarchar(max) AS JSON, modifyDate nvarchar(max) AS JSON, pointsAwardedDate nvarchar(max) AS JSON, pointsEarned float, purchaseDate nvarchar(max) AS JSON , purchasedItemCount int, rewardsReceiptItemList nvarchar(max) as json, rewardsReceiptStatus varchar(16), totalSpent float, userId varchar(32))


declare @jsondatescanned varchar(max)
declare @jsonfinisheddate varchar(max)
declare @jsonmodifydate varchar(max)
declare @jsonpointsawardeddate varchar(max)
declare @jsonpurchasedate varchar(max)
declare @jsonreceiptslist varchar(max)

select @iterator = max(rownumber) from @receiptsholding

while @iterator>0 begin

select @jsoncreatedDate = createDate,  @json_id=receiptId, @jsondatescanned=datescanned, @jsonfinisheddate=finisheddate, @jsonmodifydate= modifydate, @jsonpointsawardeddate= pointsawardeddate, 
@jsonpurchasedate= purchasedate, @jsonreceiptslist=rewardsReceiptItemList
from @receiptsholding
where rownumber=@iterator


insert dbo.Receipts_Fact 

select receiptId, bonuspointsearned, bonuspointsearnedreason, 
DATEADD(S, CONVERT(int,LEFT(createdate, 10)), '1970-01-01'), 
DATEADD(S, CONVERT(int,LEFT(datescanned, 10)), '1970-01-01'),  
DATEADD(S, CONVERT(int,LEFT(finisheddate, 10)), '1970-01-01'), 
DATEADD(S, CONVERT(int,LEFT(modifydate, 10)), '1970-01-01'), 
DATEADD(S, CONVERT(int,LEFT(pointsawardeddate, 10)), '1970-01-01'), 
pointsearned,
DATEADD(S, CONVERT(int,LEFT(purchasedate, 10)), '1970-01-01'), 
purchaseditemcount,
rewardsreceiptstatus,
totalspent,
userid
from(select (select value from openjson(@json_id))receiptId,
bonuspointsearned, bonuspointsearnedreason, 
(select value from openjson(@jsoncreatedDate)) createdate,
(select value from openjson(@jsondatescanned)) datescanned,
(select value from openjson(@jsonfinisheddate)) finisheddate,
(select value from openjson(@jsonmodifydate)) modifydate,
(select value from openjson(@jsonpointsawardeddate)) pointsawardeddate,
pointsearned,
(select value from openjson(@jsonpurchasedate)) purchasedate,
purchaseditemcount,
rewardsreceiptstatus,
totalspent,
userid
from @receiptsholding where rownumber=@iterator)a

 /*Parse out receipt list into name value attribute pairs*/

declare @attributesholding table(receiptId varchar(64), receiptlist nvarchar(max)) 
declare @attributesholding2 table(receiptId varchar(64), receiptlist nvarchar(max), rownumber int) 

insert @attributesholding

Select (select value from openjson(@json_id)) a, value from openjson(@jsonreceiptslist)  

set @iterator=@iterator-1 
end

insert @attributesholding2
select *, row_number() over (order by receiptId) from @attributesholding

select @iterator = max(rownumber) from @attributesholding2

while @iterator>0 begin

select @jsonreceiptslist=receiptlist, @json_id=receiptId
from @attributesholding2
where rownumber=@iterator

insert dbo.Receipts_List_Name_Value

select @json_id receipt_id, [key], value  
FROM OPENJSON(@jsonreceiptslist)


set @iterator=@iterator-1 
end

/*Dynamically pivot attributes*/

declare @agg table ([name] varchar(64) )
insert @agg
select distinct name from dbo.Receipts_List_Name_Value
declare @string nvarchar(max) = (select STRING_AGG('['+name+']',',') from @agg)


if object_id('dbo.Receipts_List_Attributes') is not null
drop table dbo.Receipts_List_Attributes

exec(
'select receiptid, '+ @string+' into dbo.Receipts_List_Attributes from 
(select *, row_number() over(partition by receiptid order by receiptid) rn from dbo.Receipts_List_Name_Value)A
pivot(min(value) for name in ('+ @string+'))a')


/*Data Count Check*/

select count(*) from dbo.Dim_Users 
select count(*) from dbo.Dim_Brands 
select count(*) from dbo.Receipts_Fact 
select count(*) from dbo.Receipts_List_Name_Value 
select count(*) from dbo.Receipts_List_Attributes
