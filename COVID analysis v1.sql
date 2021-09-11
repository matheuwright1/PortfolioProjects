
SELECT *
FROM PortfolioProject1.dbo.COVIDdeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1.dbo.COVIDdeaths2
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total cases vs total deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DailyDeathPercentage
FROM PortfolioProject1.dbo.COVIDdeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

--Countries highest total cases compared to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject1.dbo.COVIDdeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY location;

--Countries highest total deaths compared to population
SELECT location, population, MAX(cast(total_deaths as int)) as HighestDeathCount, MAX((cast(total_deaths as int)/population))*100 AS PercentPopulationDeath
FROM PortfolioProject1.dbo.COVIDdeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY location;

--Rank Countries highest total deaths
SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM PortfolioProject1.dbo.COVIDdeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC;

----Total deaths by continent - not for project
--SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount
--FROM PortfolioProject1.dbo.COVIDdeaths
--WHERE continent IS NULL
--GROUP BY location
--ORDER BY HighestDeathCount DESC;

----countries first data point are different dates causing contininent population per date to change
--SELECT location, MIN(date)
--FROM PortfolioProject1.dbo.COVIDdeaths
--GROUP BY location
--ORDER BY 1;

--Continents highest total deaths compared to population
DROP VIEW IF EXISTS ForcontintentAnalysis;

CREATE VIEW ForcontintentAnalysis AS
SELECT continent, date, SUM(population) AS totalpopulation, SUM(cast(total_deaths as int)) as ContinentDeathsPerDay, SUM(total_cases) AS HighestInfectionCount
FROM PortfolioProject1.dbo.COVIDdeaths
WHERE continent IS NOT NULL
GROUP BY continent, date
--ORDER BY continent, date
;

SELECT continent, MAX(totalpopulation) AS population, MAX(ContinentDeathsPerDay) AS HighestDeathCount, (MAX(ContinentDeathsPerDay)/MAX(totalpopulation))*100 AS PercentPopulationDeath
FROM ForcontintentAnalysis
GROUP BY continent
ORDER BY continent;

--Continents highest total cases compared to population
SELECT continent, MAX(totalpopulation) AS population, MAX(HighestInfectionCount) as HighestInfectionCount, (MAX(HighestInfectionCount)/MAX(totalpopulation))*100 AS PercentPopulationInfected
FROM ForcontintentAnalysis
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY continent;



--Total deaths by continent - wrong count but suits project
SELECT continent, MAX(cast(total_deaths as int)) as Deathcount
FROM PortfolioProject1.dbo.COVIDdeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Deathcount DESC;

----detirmining that a locations population doesnt differ
--CREATE VIEW countrypopulation AS
--SELECT location, MAX(population) AS MaxPop, AVG(population) AvPop
--FROM PortfolioProject1.dbo.COVIDdeaths
--WHERE continent IS NOT NULL
--GROUP BY location;

----SELECT location
----FROM countrypopulation
----WHERE MaxPop != AvPop;


-- Same as above currently but could be used later!!
--DROP VIEW IF EXISTS ForContinentAnalysis2;

--CREATE VIEW ForContinentAnalysis2 AS	
--SELECT location, continent, MAX(population) AS population, MAX(cast(total_deaths as int)) as HighestDeathCount, MAX((cast(total_deaths as int)/population))*100 AS PercentPopulationDeath 
--FROM PortfolioProject1.dbo.COVIDdeaths
--WHERE continent IS NOT NULL
--GROUP BY location, continent
--ORDER BY continent, location;

--SELECT continent, SUM(population) AS totalpopulation, SUM(HighestDeathCount) as HighestDeathCount, (SUM(HighestDeathCount)/SUM(population))*100 AS PercentPopulationDeath
--FROM ForContinentAnalysis2
--WHERE continent IS NOT NULL
--GROUP BY continent
--ORDER BY continent;

-- GLobal numbers
SELECT date, SUM(population) World_Population, SUM(new_cases) new_cases, SUM(total_cases) as TotalGlobalCases, (SUM(total_cases)/SUM(population))*100 AS PercentPopulationCases
FROM PortfolioProject1.dbo.COVIDdeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;


DROP VIEW IF EXISTS Global_numbers;

CREATE VIEW Global_numbers AS
SELECT date, SUM(new_cases) daily_cases, SUM(CAST(new_deaths as int)) as daily_deaths, (SUM(CAST(new_deaths as int))/SUM(new_cases))*100 AS DailyDeathPercentage
FROM PortfolioProject1.dbo.COVIDdeaths
WHERE continent IS NOT NULL
GROUP BY date;

SELECT *, 
SUM(daily_cases) OVER (ORDER by date) AS rolling_CaseNumbers,
SUM(daily_deaths) OVER (ORDER by date) AS rolling_DeathNumbers,
(SUM(daily_deaths) OVER (ORDER by date)/ SUM(daily_cases) OVER (ORDER by date))*100 AS rolling_DeathPercentage
FROM Global_numbers
ORDER BY date;

-- Using CTE (Common Table Expression)
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_VacCount)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER by dea.location, dea.date) AS rolling_VacCount
--,(rolling_VacCount/population)*100 AS rolling_VacPercentage
FROM PortfolioProject1.dbo.COVIDdeaths AS dea
JOIN PortfolioProject1.dbo.COVIDvaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1, 2, 3;
)

SELECT *, ROUND((rolling_VacCount/population)*100,3) AS rolling_VacPercentage
FROM PopvsVac
ORDER BY continent, location, date;

-- TEMP TABLE same table as above
DROP TABLE IF EXISTS #PercentagePopulationsVaccination

CREATE TABLE #PercentagePopulationsVaccination
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_VacCount numeric
)

INSERT INTO #PercentagePopulationsVaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER by dea.location, dea.date) AS rolling_VacCount
--,(rolling_VacCount/population)*100 AS rolling_VacPercentage
FROM PortfolioProject1.dbo.COVIDdeaths AS dea
JOIN PortfolioProject1.dbo.COVIDvaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1, 2, 3;

SELECT *, ROUND((rolling_VacCount/population)*100,3) AS rolling_VacPercentage
FROM #PercentagePopulationsVaccination
ORDER BY continent, location, date;