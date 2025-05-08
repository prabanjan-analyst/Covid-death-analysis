USE covid_analysis;

SELECT * FROM CovidDeaths ORDER BY 3,4;

SELECT * FROM CovidVaccinations ORDER BY 3,4;

-- Data that we are using
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM CovidDeaths ORDER BY 1,2;

-- Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathPercent
FROM CovidDeaths ORDER BY 1,2;

-- Death Percent in India
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathPercent
FROM CovidDeaths 
WHERE location = 'india' 
ORDER BY 1,2;

-- Total cases vs Population
-- Percentage of population got covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS covidInfectedPercent
FROM CovidDeaths ORDER BY 1,2;

-- Percentage of population got covid in India
SELECT location, date, total_cases, population, (total_cases/population)*100 AS covidInfectedPercent
FROM CovidDeaths 
WHERE location = 'india' 
ORDER BY 1,2;

-- Countries with Highest Infection Rate compared to population
SELECT location, population, MAX(total_cases) AS highestInfected, 
	MAX((total_cases/population))*100 AS infectedPopulationPercent
	FROM CovidDeaths 
	GROUP BY location, population 
	ORDER BY infectedPopulationPercent DESC;

-- Countries with Highest Death count 
SELECT location, MAX(total_deaths) AS highestDeathCount
FROM CovidDeaths 
GROUP BY location 
ORDER BY highestDeathCount DESC;

-- The Total_Deaths is an VARCHAR datatype so we change the datatype as INT
-- Some data have continent is null and location is Asia and world so we remove the null values in continent
SELECT location, MAX(CAST(total_deaths AS INT)) AS highestDeathCount
FROM CovidDeaths 
WHERE continent IS NOT NULL 
GROUP BY location 
ORDER BY highestDeathCount DESC;

-- Total Death count by Continent
SELECT continent, MAX(CAST(total_deaths AS INT)) AS highestDeathCount
FROM CovidDeaths 
GROUP BY continent 
ORDER BY highestDeathCount DESC;

-- Total Death count by Continent without null values
SELECT continent, MAX(CAST(total_deaths AS INT)) AS highestDeathCount
FROM CovidDeaths 
WHERE continent IS NOT NULL 
GROUP BY continent 
ORDER BY highestDeathCount DESC;

-- Global DeathPercent
-- new_deaths is a VARCHAR, so we change its datatype as INT
SELECT SUM(new_cases) AS total_new_cases, SUM(CAST(new_deaths AS INT)) AS total_new_deaths,
	(SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS deathPercent
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total population vs Vaccination
SELECT death.continent, death.location, death.date, death.population, vaccin.new_vaccinations,
	SUM(CAST(vaccin.new_vaccinations AS INT)) 
	OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS peopleVaccinated
FROM CovidDeaths death JOIN CovidVaccinations vaccin 
	ON death.location = vaccin.location
	AND death.date = vaccin.date
WHERE death.continent IS NOT NULL;


-- Use CTE for getting Percentage
WITH populationVaccinated (continent, location, date, population, vaccinations, peopleVaccinated)
AS (
	SELECT death.continent, death.location, death.date, death.population, vaccin.new_vaccinations,
		SUM(CAST(vaccin.new_vaccinations AS INT))
		OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS peopleVaccinated
	FROM CovidDeaths death JOIN CovidVaccinations vaccin
	ON death.location = vaccin.location
	AND death.date = vaccin.date
	WHERE death.continent IS NOT NULL
)
SELECT *, (peopleVaccinated/population) *100 AS vaccinatedPopulationPercent
FROM populationVaccinated;

-- To create TEMP Table
DROP TABLE IF EXISTS #vaccinatedPopulationPercent
CREATE TABLE #vaccinatedPopulationPercent(
	continent NVARCHAR(255),
	location NVARCHAR(255),
	date datetime,
	population NUMERIC,
	new_vaccinations NUMERIC,
	peopleVaccinated NUMERIC
) 

-- INSERT the values into the TEMP Table
INSERT INTO #vaccinatedPopulationPercent
	SELECT death.continent, death.location, death.date, death.population, vaccin.new_vaccinations,
		SUM(CAST(vaccin.new_vaccinations AS INT))
		OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS peopleVaccinated
	FROM CovidDeaths death JOIN CovidVaccinations vaccin
	ON death.location = vaccin.location
	AND death.date = vaccin.date
	WHERE death.continent IS NOT NULL;

SELECT * FROM #vaccinatedPopulationPercent;

-- Create a view for later visulization
CREATE VIEW vaccinatedPopulation AS
SELECT death.continent, death.location, death.date, death.population, vaccin.new_vaccinations,
	SUM(CAST(vaccin.new_vaccinations AS INT)) 
	OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS peopleVaccinated
FROM CovidDeaths death JOIN CovidVaccinations vaccin 
	ON death.location = vaccin.location
	AND death.date = vaccin.date
WHERE death.continent IS NOT NULL;

SELECT * FROM vaccinatedPopulation;