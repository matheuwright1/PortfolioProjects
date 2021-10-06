SELECT *
FROM PortfolioProject1.dbo.NashvilleHousing;

-- Standardize Date Format

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject1.dbo.NashvilleHousing;

UPDATE PortfolioProject1.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate);

--OR

ALTER TABLE PortfolioProject1.dbo.NashvilleHousing
ADD SaleDateConverted Date;

UPDATE PortfolioProject1.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);

-- Populate Property Address data
-- Join table with itself, as NULL Property addresses are due to duplicate entries for same ParcelID
--ISNULL shows a address unless its null then shows b address for same ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject1.dbo.NashvilleHousing a
JOIN PortfolioProject1.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- update Nashville housing to replace as above.
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject1.dbo.NashvilleHousing a
JOIN PortfolioProject1.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

--  Breaking out Address into Individual Colums (Address, City, State)

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
		SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS Town
FROM PortfolioProject1.dbo.NashvilleHousing;


ALTER TABLE PortfolioProject1.dbo.NashvilleHousing
ADD StreetAddress NVARCHAR(255),
	CityAddress NVARCHAR(255);

UPDATE PortfolioProject1.dbo.NashvilleHousing
SET StreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
	CityAddress = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress));


-- Breaking out OwnerAddress using PARSENAME
-- PARSENAME only searches for periods, not commas, so we replace ',' for '.'
-- PARSENAME searches from back to front for a common a segments
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), 
		PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
		PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject1.dbo.NashvilleHousing;

ALTER TABLE PortfolioProject1.dbo.NashvilleHousing
ADD OwnerStreet NVARCHAR(255),
	OwnerCity NVARCHAR(255),
	OwnerState NVARCHAR(255);

UPDATE PortfolioProject1.dbo.NashvilleHousing
SET OwnerStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

SELECT * 
FROM  PortfolioProject1.dbo.NashvilleHousing;


-- Change Y and N to Yes and NO in SoldAsVacant field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject1.dbo.NashvilleHousing
GROUP BY SoldAsVacant;

SELECT SoldAsVacant, 
CASE WHEN SoldASVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'NO'
	ELSE SoldAsVacant 
	END AS 

UPDATE PortfolioProject1.dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldASVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'NO'
						ELSE SoldAsVacant 
						END

-- Remove Duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
				 PARTITION BY ParcelID,
							  PropertyAddress,
							  SalePrice,
							  SaleDate,
							  LegalReference,
							  Ownername
							  ORDER BY UniqueID
						) num_appearances
FROM  PortfolioProject1.dbo.NashvilleHousing
--ORDER BY ParcelID 
	)

DELETE
FROM RowNumCTE
WHERE num_appearances > 1;

-- Delete Unused Columns
SELECT *
FROM PortfolioProject1.dbo.NashvilleHousing

ALTER TABLE PortfolioProject1.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress;