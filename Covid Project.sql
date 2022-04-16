/*Covid 19 Data Exploration

Skills used:  Joins, CTE's Temp Tables, Windows Functions, Aggregrate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM PortfolioProject..CovidVaccinations
WHERE continent is not null
ORDER BY 3,4

--Select Data that we are going to be starting with


SELECT location, date, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--Total Cases vs. Total Deaths
--Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'

ORDER BY 1,2

--Total Cases vs. Population
--Show what percentage of total population is infected with covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS PositivePercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--Infection Rate vs. Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
WHERE continent is not null
Group By location, population
Order By PercentPopulationInfected desc

--Showing Countries with the Highest Death Count per Population

SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
WHERE continent is not null
Group By location
Order By TotalDeathCount desc

--Continent break down

--Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
WHERE continent is not null
AND location not like '%income%'
Group By continent
Order By TotalDeathCount desc


--Total Deaths by income level


SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
WHERE continent is null
AND location like '%income%'
Group By location
Order By TotalDeathCount desc


--Overall Global Numbers

SELECT SUM(new_cases) AS DailyNewCases, SUM(cast(new_deaths as int)) AS DailyDeaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--Daily Global Numbers

SELECT date, SUM(new_cases) AS DailyNewCases, SUM(cast(new_deaths as int)) AS DailyDeaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


--Looking at total population vs. vaccination rate

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS DailyVaccinationCount,
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
Order By 2, 3


--USE CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, DailyVaccinationCount)
AS (SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS DailyVaccinationCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null)

SELECT *, (DailyVaccinationCount/population)*100 AS DailyVaccinationPercentage
FROM PopVsVac

--TEMP TABLE

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),`
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated Bigint
)

INSERT INTO #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
