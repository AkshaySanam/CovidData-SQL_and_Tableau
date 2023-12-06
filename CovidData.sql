--select * from CovidVaccine
--order by 3,4;

--To describe table data type:
--EXEC sp_help CovidVaccine;

select * from coviddeaths
order by 3,4;

--EXEC sp_help CovidDeaths

--select Data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
from coviddeaths
order by 1,2;

-- looking at the Total Cases vs Total Deaths
--shows likelihood of dying if you contract covid in your country
--use the following code to convert into float datatype when ''Null" . Some of the data in "Numeric" data type is actually float, thats why we need to convert it.
--CONVERT(float, total_deaths): Converts the total_deaths column to a floating-point number.
--CONVERT(float, total_cases): Converts the total_cases column to a floating-point number.
--NULLIF(CONVERT(float, total_cases), 0): Handles division by zero by returning NULL if total_cases is 0; otherwise, it returns the converted value of total_cases.
--The division is performed: (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)).
--The result is multiplied by 100 to get the percentage.

Select location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
from coviddeaths
where location like '%states' and continent is not null
order by 1,2;

--Looking at the total cases vs Population
--shows what % of population got covid
Select location, date, total_cases, population,
(total_cases/population)*100 AS PercentPopulationInfected
from coviddeaths
where location like '%states' and continent is not null
order by 1,2;

-- Looking at countries with highest infection rate compared to population

select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from coviddeaths
where continent is not null
group by location, population
order by PercentPopulationInfected DESC;

--showing countries with highest death count per population
--CAST is used to change the datatype as the total_deaths has varchar data type which will jumble the order of highestdeaths

select location, MAX(CAST(total_deaths as int)) as HighestDeaths
from coviddeaths
where continent is not null
group by location
order by HighestDeaths DESC;

--lets break it into continents
--showing continents with the highest death count per population

select continent, MAX(CAST(total_deaths as int)) as HighestDeaths
from coviddeaths
where continent is not null
group by continent
order by HighestDeaths DESC;

--Global Numbers (whole world)

SELECT SUM(new_cases) AS TotalNewCases, SUM(CAST(new_deaths AS int)) AS TotalNewDeaths, SUM(CAST(new_deaths AS int)) / NULLIF(SUM(new_cases), 0) * 100 AS DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

--JOIN coviddeath and covidvaccine table

select * from coviddeaths as death
join covidvaccine as vaccine
on death.location = vaccine.location
and death.date = vaccine.date

--Looking at total population vs vaccination

select death.continent, death.location, death.date, death.population, vaccine.new_vaccinations
from coviddeaths as death
join covidvaccine as vaccine
on death.location = vaccine.location
and death.date = vaccine.date
where death.continent is not null
order by 2,3;

select death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, SUM(CONVERT(bigint, vaccine.new_vaccinations)) 
OVER (PARTITION BY death.location order by death.location, death.date) as RollingpeopleVaccinated
from coviddeaths as death
join covidvaccine as vaccine
on death.location = vaccine.location
and death.date = vaccine.date
where death.continent is not null
order by death.location, death.date;

-- CTE

WITH popvsvac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
AS
(select death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, SUM(CONVERT(bigint, vaccine.new_vaccinations)) OVER 
(PARTITION BY death.location order by death.location, death.date) as RollingpeopleVaccinated
from coviddeaths as death
join covidvaccine as vaccine
on death.location = vaccine.location
and death.date = vaccine.date
where death.continent is not null and vaccine.new_vaccinations is not null)
select *, (rollingpeoplevaccinated/population)*100
from popvsvac;

