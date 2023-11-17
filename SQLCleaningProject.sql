/*
SQL Cleaning Project
*/

-- Test that data was imported correctly with simple SELECT statement
SELECT
    *
FROM
    CleaningProject.dbo.NashvilleHousing

-- Change date format
SELECT
    SaleDate,
    CONVERT(date,SaleDate)
FROM
    CleaningProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(date,SaleDate)


-- Populate null Property Address data
-- Use existing addresses associated with ParcelID
-- JOIN, ISNULL, UPDATE
SELECT
    L.ParcelID,
    L.PropertyAddress,
    R.ParcelID,
    R.PropertyAddress,
    ISNULL(L.PropertyAddress, R.PropertyAddress)
FROM
    NashvilleHousing L
JOIN NashvilleHousing R
    ON L.ParcelID = R.ParcelID
    AND L.UniqueID <> R.UniqueID
WHERE L.PropertyAddress IS NULL

UPDATE L
SET PropertyAddress = ISNULL(L.PropertyAddress, R.PropertyAddress)
FROM
    NashvilleHousing L
JOIN NashvilleHousing R
    ON L.ParcelID = R.ParcelID
    AND L.UniqueID <> R.UniqueID
WHERE L.PropertyAddress IS NULL


-- Split property addresses into separate street and city fields and add new columns for each
-- SUBSTRING() + CHARINDEX() + LEN()
SELECT
    PropertyAddress,
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS PropertyStreet,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress)) AS PropertyCity
FROM
    NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertyStreet VARCHAR(255), PropertyCity VARCHAR(255)

UPDATE NashvilleHousing
SET
    PropertyStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1),
    PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress))


-- Split owner addresses into separate street and city fields and add new columns for each
-- PARSENAME() + REPLACE()
SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM
    NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerStreet VARCHAR(255), OwnerCity VARCHAR(255), OwnerState VARCHAR(255)

UPDATE NashvilleHousing
SET
    OwnerStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Replace all instances of 'Y' and 'N' in SoldAsVacant with 'Yes' and 'No'
-- CASE
SELECT
    DISTINCT
    (SoldAsVacant)
FROM
    NashvilleHousing

SELECT
    SoldAsVacant,
    CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END AS NormSoldAsVacant
FROM
    NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END

-- Remove duplicates
-- CTE + PARTITION BY
WITH RowNumCTE AS(
SELECT
    *,
    ROW_NUMBER() OVER(
        PARTITION BY ParcelID,
        PropertyAddress,
        SalePrice,
        SaleDate,
        LegalReference
        ORDER BY UniqueID) AS row_num
FROM
    NashvilleHousing
)

DELETE
FROM RowNumCTE
WHERE row_num > 1
