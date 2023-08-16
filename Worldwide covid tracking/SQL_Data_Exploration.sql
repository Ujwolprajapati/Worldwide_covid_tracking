
SELECT *
FROM portfolio.coviddeaths
ORDER BY location, date;

SELECT *
FROM portfolio.covidvaccinations
ORDER BY location, date ;

-- select key variables we're interested in
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolio.coviddeaths 
ORDER BY location, date;

-- calculate covid death rate 
SELECT location, date, total_cases, total_deaths, population, (total_deaths/total_cases)*100 AS death_rate
FROM portfolio.coviddeaths 
WHERE location like '%States%'
ORDER BY location, date;

-- calculate covid infection rate
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infection_rate
FROM portfolio.coviddeaths 
WHERE location like '%States'
ORDER BY location, date;

-- calculate highest covid infection count & rate across the countries
SELECT location, population, 
       MAX(total_cases) AS highest_infection_count, 
       MAX(total_cases/population)*100 AS highest_infection_rate
FROM portfolio.coviddeaths 
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 3 DESC;

-- calculate the highest covid death count for each continent
SELECT continent,
       MAX(total_deaths) AS highest_deaths_count
FROM portfolio.coviddeaths 
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;


-- calculate the worldwide covid death rate for each day
SELECT date, SUM(new_cases), SUM(new_deaths), (SUM(new_deaths)/SUM(new_cases))*100 AS death_rate
FROM portfolio.coviddeaths 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 4;

-- join two tables together
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM portfolio.coviddeaths dea
JOIN portfolio.covidvaccinations vac
ON dea.location = vac.location 
AND dea.date = vac.date;

-- join two tables and calculate the rolling count of new vaccinations 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccination
FROM portfolio.coviddeaths dea
JOIN portfolio.covidvaccinations vac
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- CTE
WITH VacTable 
AS (
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccination
 FROM portfolio.coviddeaths dea
JOIN portfolio.covidvaccinations vac
  ON dea.location = vac.location 
  AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_vaccination/population)*100 AS vac_rate
FROM VacTable;

-- temp table
CREATE TABLE portfolio.VacRate
(
  continent VARCHAR(255),
  location VARCHAR(255), 
  date DATETIME, 
  population BIGINT,
  new_vaccinations BIGINT,
  rolling_vaccination BIGINT
);
INSERT INTO portfolio.vacrate
SELECT
    dea.continent,
    dea.location,
    STR_TO_DATE(dea.date, '%m/%d/%Y') AS converted_date,
    dea.population,
    IF(vac.new_vaccinations = '', 0, vac.new_vaccinations) AS new_vaccinations,
    SUM(IF(vac.new_vaccinations = '', 0, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, STR_TO_DATE(dea.date, '%m/%d/%Y')) AS rolling_vaccination
FROM
    portfolio.coviddeaths dea
JOIN
    portfolio.covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;

SELECT *, (rolling_vaccination/population)*100 AS vac_rate
FROM portfolio.VacRate;

