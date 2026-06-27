/*
  Top 10 production companies by number of movies released between 2000 and 2020.
  Shows the count of distinct movies, the earliest and latest production year for each company.
*/
WITH filtered_titles AS (
    SELECT id, production_year
    FROM title
    WHERE production_year BETWEEN 2000 AND 2020
)
SELECT
    cn.name AS company_name,
    ct.kind AS company_type,
    COUNT(DISTINCT ft.id) AS movie_count,
    MIN(ft.production_year) AS earliest_year,
    MAX(ft.production_year) AS latest_year
FROM filtered_titles ft
JOIN movie_companies mc
    ON mc.movie_id = ft.id
JOIN company_name cn
    ON mc.company_id = cn.id
JOIN company_type ct
    ON mc.company_type_id = ct.id
WHERE ct.kind = 'production'
GROUP BY cn.name, ct.kind
ORDER BY movie_count DESC, earliest_year ASC
LIMIT 10
