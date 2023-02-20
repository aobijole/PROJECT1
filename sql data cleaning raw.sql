/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [UniqueID ]
      ,[ParcelID]
      ,[LandUse]
      ,[PropertyAddress]
      ,[SaleDate]
      ,[SalePrice]
      ,[LegalReference]
      ,[SoldAsVacant]
      ,[OwnerName]
      ,[OwnerAddress]
      ,[Acreage]
      ,[TaxDistrict]
      ,[LandValue]
      ,[BuildingValue]
      ,[TotalValue]
      ,[YearBuilt]
      ,[Bedrooms]
      ,[FullBath]
      ,[HalfBath]
  FROM [Project Portfolio].[dbo].[USA N Housing Coop]


----DATA CLEANING IN SQL QUERIES----
Select *
from [Project Portfolio].dbo.[USA N Housing Coop]

---/////////////////////////////-----
---STANDARDIZING THE DATE FORMAT---
Select SalesDate2, CONVERT(date, saledate)
from [Project Portfolio].dbo.[USA N Housing Coop]

update [USA N Housing Coop]
set SaleDate = CONVERT(date, saledate)
		--New Date Col Added
Alter Table [USA N Housing Coop]
Add SalesDate2 Date;
		--NEwly added column updated with the proper date(format)
update [USA N Housing Coop]
set SalesDate2 = CONVERT(date, saledate)


---POPULATING THE PROPERTY ADDRESS DATA---
---///////////////\\\\\\\\\\\\\\\\\\\\\----

Select PropertyAddress
from [Project Portfolio].dbo.[USA N Housing Coop]
---where PropertyAddress is Null
group by ParcelID
---to identify which i.ds use the same adress

---to fill the Nulls, a self join would be used 
---where I.d = I.d, the address should be = to the address

select x.ParcelID, x.PropertyAddress, y.ParcelID, y.PropertyAddress, ISNULL(x.PropertyAddress, y.PropertyAddress)
from [Project Portfolio].dbo.[USA N Housing Coop] x
Join [Project Portfolio].dbo.[USA N Housing Coop] y
on x.ParcelID = y.ParcelID  ---i.e when the i.d are equal
and x.[UniqueID ]<>y.[UniqueID ]   ----but when the unique I.d'S are differenct, populate the nulls
where x.PropertyAddress is null
---This shows us where is nulls and also shows us the potential date to be populated into the nulls


---now the statement to update the null columns
update x
set PropertyAddress = ISNULL(x.PropertyAddress, y.PropertyAddress) --set propertyaddress where null 
from [Project Portfolio].dbo.[USA N Housing Coop] x
Join [Project Portfolio].dbo.[USA N Housing Coop] y
on x.ParcelID = y.ParcelID  ---i.e when the i.d are equal
and x.[UniqueID ]<>y.[UniqueID ]   ----but when the unique I.d'S are differenct, populate the nulls
where x.PropertyAddress is null

--to test it, the syntax up will return nothing when check for nulls are run.


------////////////\\\\\\\\\\\\\\\\-----
---BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS---

--to examine the address, we do:
select PropertyAddress
from [Project Portfolio].dbo.[USA N Housing Coop]
--Where propertyaddress is null
--order by ParcelID

--to seperate, we use substring and CharIndex
Select
SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1 ) as Address,
SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress) ) as Address
from [Project Portfolio].dbo.[USA N Housing Coop]

---ANOTHER WAY:NOT COMPLICATED WAY AND DIRECT

Select OwnerAddress
from [Project Portfolio].dbo.[USA N Housing Coop]

select 
PARSENAME (replace(OwnerAddress, ',', '.'),3), ---replacing the , with . makes it recognisable and then the sliting can start
PARSENAME (replace(OwnerAddress, ',', '.'),2),		---parsename starts from the back i.e the last item that is why the arrangement is starting from 3,2,1
PARSENAME (replace(OwnerAddress, ',', '.'),1)
from [Project Portfolio].dbo.[USA N Housing Coop]

--then proceed to---
Alter Table [USA N Housing Coop]
Add OwnerSplitAddress Nvarchar(255)
		--NEwly added column updated with the proper Address

update [USA N Housing Coop]
set OwnerSplitAddress = PARSENAME (replace(OwnerAddress, ',', '.'),3) ---the address parse is inserted and run

Alter Table [USA N Housing Coop]
Add OwnerSplitCity Nvarchar(255)
		

update [USA N Housing Coop]
set OwnerSplitCity = PARSENAME (replace(OwnerAddress, ',', '.'),2) ---the City parse is inserted and run
---OWNER ADDRESS

Alter Table [USA N Housing Coop]
Add OwnersplitState Nvarchar(255)
		--NEwly added column updated with the proper City

update [USA N Housing Coop]
set OwnerSplitState = PARSENAME (replace(OwnerAddress, ',', '.'),1)  ---the State parse is inserted and run
---OWNER ADDRESS

--To view
select * 
from [Project Portfolio].dbo.[USA N Housing Coop]
--...........---


------CHanging Y and N to Yes and No in 'Sold as Vacant' field-----
------///////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\--------
select distinct SoldAsVacant, count(soldasvacant)
from [Project Portfolio].dbo.[USA N Housing Coop]  ---4 distincts are seen y,n,yes.no hence need for unification to y,n /Yes,No
group by SoldAsVacant
order by 2

select SoldAsVacant,
case
	when SoldAsVacant ='Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end
from [Project Portfolio].dbo.[USA N Housing Coop]

---then the main statement to update the table
update [USA N Housing Coop]
set SoldAsVacant =
	case
	when SoldAsVacant ='Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end

select distinct soldasvacant
from [Project Portfolio].dbo.[USA N Housing Coop]


---------DEDUPLICATION PROCESS---------
--------////////////////\\\\\\\\\\\\----
---USING CTE AND WINDOWS FUNCTION FOR DETECTION AND REMOVAL----

--FIRST PARTITION THE DATA (RANK/ORDER RANK, DENSE RANK ETC TO ID THE DUPLICATES)

--DETERMINE WHAT YOU WILL PARTITION BY
SELECT *
FROM [Project Portfolio].DBO.[USA N Housing Coop]

SELECT *,
ROW_NUMBER() OVER
(PARTITION BY ParcelID,
			  PropertyAddress,
			  SalePrice,SalesDate,
			  LegalRefrence
 ORDER BY	  UniqueID)
 row_num
FROM [Project Portfolio].DBO.[USA N Housing Coop]

---insert the above statement in a CTE to display the duplicates by the row-number of 2 and above
With RowNumCTE as (
select *,
ROW_NUMBER() OVER
(PARTITION BY ParcelID,
			  PropertyAddress,
			  SalePrice,
			  SaleDate,
			  LegalReference
 ORDER BY	  UniqueID)
 row_num
FROM [Project Portfolio].DBO.[USA N Housing Coop]
)
select * ---after using select to view, we can replace select with delete to then delete duplicates by the row number of 2 and above
from RowNumCTE
where row_num >1
---order by propertyAddress
---to confirm if duplicates are still there, just rerun the above statement using (select *) instead of delete

-------DELETE UNUSED COLUMNS-------
-------////////\\\\\\\\\-----------

Alter Table [Project Portfolio].DBO.[USA N Housing Coop]
drop column OwnerAddress, 
			TaxDistrict, 
			PropertyAddress,
			SaleDate 
			
