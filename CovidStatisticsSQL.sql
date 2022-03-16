-- Total Cases by country

SELECT location, MAX(total_cases) AS Total_Cases
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY 2 DESC

-- Total Cases by country per population

SELECT location, MAX(total_cases) AS Total_Cases, population, ROUND((MAX(total_cases)/population) *100,2) AS CasesPerPopulation
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY 4 DESC

-- High income vs low income countries regarding cases by population

SELECT dea.location, dea.population, 
MAX(dea.total_cases) AS Total_Cases, 
ROUND((MAX(dea.total_cases)/dea.population) *100,2) AS CasesPerPopulation, 
MAX(CAST(vac.People_Vaccinated AS INT)) AS People_Vaccinated, 
ROUND(MAX(CAST(vac.People_Vaccinated AS INT)) /dea.population *100,2) AS Vaccinated_People_Per_Population
FROM CovidDeaths dea
FULL JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population
HAVING dea.population >= 1000000
ORDER BY Vaccinated_People_Per_Population DESC

-- Total Test and Total Test per Population

SELECT dea.location, dea.population, 
MAX(dea.total_cases) AS Total_Cases, 
ROUND((MAX(dea.total_cases)/dea.population) *100,2) AS CasesPerPopulation, 
MAX(CAST(vac.People_Vaccinated AS INT)) AS People_Vaccinated, 
ROUND(MAX(CAST(vac.People_Vaccinated AS INT)) /dea.population *100,2) AS Vaccinated_People_Per_Population,
MAX(CAST(vac.total_tests AS INT)) AS Total_Tests,
ROUND(MAX(CAST(vac.total_tests AS INT)) /dea.population *100,2) AS Total_Tests_Per_Population
FROM CovidDeaths dea
FULL JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population
HAVING dea.population >= 1000000
ORDER BY Total_Tests_Per_Population DESC

-- Total Deaths per population

SELECT 
	location, 
	MAX(CAST(total_deaths AS INT)) AS Total_Deaths, 
	population, 
	ROUND((MAX(CAST(total_deaths AS INT))/population) * 100,2) AS DeathsPerPopulation
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY 4 Desc

-- Using CTE and Partition by, finding how vaccine going by country day by day

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, VaccineCounter)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as VaccineCounter
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, ROUND((VaccineCounter/Population)*100,2) AS VaccinePercentage
From PopvsVac
order by 2,3

-- Using Temp table, finding how tests are going by country everyday

DROP Table if exists #PercentPopulationTested
Create Table #PercentPopulationTested
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_tests numeric,
Test_Counter numeric
)

Insert into #PercentPopulationTested
Select dea.continent, dea.location, dea.date, dea.population, vac.new_tests
, SUM(CONVERT(bigint,vac.new_tests)) OVER (Partition by dea.Location Order by dea.location, dea.Date)
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (Test_Counter /Population)*100  AS TestOercentage
From #PercentPopulationTested
Order by 2,3

-- Using Creating View, finding how cases raising by country day by day

Create View ProgressCases as
Select dea.continent, dea.location, dea.date, dea.population, dea.new_cases
, SUM(CONVERT(bigint,dea.new_cases)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as Case_Counter
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select *
from ProgressCases
order by 2,3