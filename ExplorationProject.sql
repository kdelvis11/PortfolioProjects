-- *Test that data has been correctly imported
SELECT DISTINCT
    location
FROM
    ExplorationProject.coviddeaths
LIMIT 15
    
-- *Total death rate by country
SELECT 
    location,
    SUM(total_cases) AS TotalCases,
    SUM(total_deaths) AS TotalDeaths,
    ROUND(SUM(total_deaths) / SUM(total_cases) * 100,
            2) AS DeathRate
FROM
    ExplorationProject.coviddeaths
WHERE continent <> ''
GROUP BY location
-- ORDER BY DeathRate DESC

-- *Total death rate by date
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    ROUND((total_deaths / total_cases) * 100, 2) AS DeathRate
FROM
    ExplorationProject.coviddeaths
ORDER BY location , date

-- *Total death rate by date in the U.S.
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    ROUND((total_deaths / total_cases) * 100, 2) AS DeathRate
FROM
    ExplorationProject.coviddeaths
WHERE
    location = 'United States'
ORDER BY location , date

-- *Total cases vs population in the U.S.
SELECT 
    location,
    date,
    total_cases,
    population,
    ROUND((total_cases / population) * 100, 5) AS CaseRate
FROM
    ExplorationProject.coviddeaths
WHERE
    location = 'United States'
ORDER BY location , date

-- *Countries with highest case rate relative to population as of 2023-11-02
SELECT
    location,
    MAX(ROUND((total_cases / population) * 100, 2)) AS PercentInfected
FROM
    ExplorationProject.coviddeaths
WHERE continent <> ''
GROUP BY location
ORDER BY PercentInfected DESC

-- *Countries with highest case rate relative to population as of 2021-04-30
-- *(vaccines started to become available)
SELECT 
    location,
    MAX(ROUND((total_cases / population) * 100, 2)) AS PercentInfected
FROM
    ExplorationProject.coviddeaths
WHERE
    date = '2021-04-30' AND continent <> ''
GROUP BY location
ORDER BY PercentInfected DESC

-- *Countries with the highest death rate relative to population as of 2023-11-02
SELECT 
    location,
    population,
    MAX(total_deaths) AS TotalDeathCount,
    MAX(ROUND((total_deaths / population) * 100, 2)) AS PercentDeaths
FROM
    ExplorationProject.coviddeaths
WHERE continent <> ''
GROUP BY location, population
ORDER BY PercentDeaths DESC

-- *Countries with the highest death rate relative to population as of 2023-04-30
-- *(about when vaccines started to become available)
SELECT 
    location,
    population,
    MAX(total_deaths) AS TotalDeathCount,
    MAX(ROUND((total_deaths / population) * 100, 2)) AS PercentDeaths
FROM
    ExplorationProject.coviddeaths
WHERE date = '2021-04-30' AND continent <> ''
GROUP BY location, population
ORDER BY PercentDeaths DESC

-- *Total deaths by country as of 2023-11-02
SELECT 
    location,
    MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM
    ExplorationProject.coviddeaths
WHERE continent <> ''
GROUP BY location
ORDER BY TotalDeathCount DESC


-- *Total deaths by continent as of 2023-11-02
SELECT 
    location,
    MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM
    ExplorationProject.coviddeaths
WHERE
    continent = ''
        AND location NOT IN ('World',
        'High Income',
        'Upper middle income',
        'Lower middle income',
        'European Union',
        'Low Income')
GROUP BY location
ORDER BY TotalDeathCount DESC


-- *Global new cases and new deaths by date
SELECT 
    date,
    SUM(new_cases) AS NewCases,
    SUM(new_deaths) AS NewDeaths
FROM
    ExplorationProject.coviddeaths
WHERE continent <> ''
GROUP BY date
ORDER BY date

-- *Total global reported cases, deaths, death rate as of 2023-11-02
SELECT 
    SUM(new_cases) AS Cases,
    SUM(new_deaths) AS Deaths,
    ROUND(SUM(new_deaths) / SUM(new_cases) * 100,
            3) AS DeathRate
FROM
    ExplorationProject.coviddeaths
WHERE
    continent <> ''
ORDER BY date

-- *Percentage of U.S. population with full vaccination status
SELECT 
    D.location,
    D.date,
    D.population,
    V.people_fully_vaccinated,
    (people_fully_vaccinated/population)*100 AS PercentPopFullyVaccinated
FROM
	ExplorationProject.coviddeaths AS D
JOIN ExplorationProject.covidvaccinations AS V
	ON D.location = V.location
    AND D.date = V.date
WHERE D.location = 'United States'
GROUP BY D.location, D.date, D.population, V.people_fully_vaccinated


-- *Total global population vs total vaccinations as of 2023-11-02
SELECT 
    D.location,
    D.population,
    SUM(new_vaccinations) AS TotalVaccinations
FROM
	ExplorationProject.coviddeaths AS D
JOIN ExplorationProject.covidvaccinations AS V
	ON D.location = V.location
    AND D.date = V.date
WHERE D.location = 'World'
GROUP BY D.location, D.population

-- *New vaccinations by date + rolling total by date for each country
SELECT 
    D.location,
    D.date,
    V.new_vaccinations,
    SUM(CONVERT(V.new_vaccinations, SIGNED))
		OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS RollingTotalVaccinations
FROM
	ExplorationProject.coviddeaths AS D
JOIN ExplorationProject.covidvaccinations AS V
	ON D.location = V.location
    AND D.date = V.date
WHERE D.continent <> ''
GROUP BY D.location, D.date, V.new_vaccinations

-- *Use CTE to show/store vaccinations administered per capita (per person) in each country
WITH VaccinationsPerCapita (location, date, population, new_vaccinations, rolling_total_vaccinations)
AS (
SELECT 
    D.location,
    D.date,
    D.population,
    V.new_vaccinations,
    SUM(CONVERT(V.new_vaccinations, SIGNED))
		OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS RollingTotalVaccinations
FROM
	ExplorationProject.coviddeaths AS D
JOIN ExplorationProject.covidvaccinations AS V
	ON D.location = V.location
    AND D.date = V.date
WHERE D.continent <> ''
GROUP BY D.location, D.date, D.population, V.new_vaccinations
)

-- *Use data stored in CTE to calculate number of vaccination doses per person in each country
-- *Must be run with CTE above
SELECT 
    *,
    (rolling_total_vaccinations / population) AS VaccinationDosesPerCapita
FROM
    VaccinationsPerCapita

-- Create View to store vax does by date
CREATE VIEW TotalVaccinationDosesByDay AS
SELECT 
    D.location,
    D.date,
    D.population,
    V.new_vaccinations,
    SUM(CONVERT(V.new_vaccinations, SIGNED))
		OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS RollingTotalVaccinations
FROM
	ExplorationProject.coviddeaths AS D
JOIN ExplorationProject.covidvaccinations AS V
	ON D.location = V.location
    AND D.date = V.date
WHERE D.continent <> ''
GROUP BY D.location, D.date, D.population, V.new_vaccinations
