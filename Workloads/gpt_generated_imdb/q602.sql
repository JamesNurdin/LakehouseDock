WITH movies_by_company_decade AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        cn.country_code,
        mc.company_type_id,
        CAST(FLOOR(t.production_year / 10) * 10 AS integer) AS decade_start,
        COUNT(*) AS movies_in_decade
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN company_name cn
        ON mc.company_id = cn.id
    WHERE t.production_year IS NOT NULL
    GROUP BY
        cn.id,
        cn.name,
        cn.country_code,
        mc.company_type_id,
        CAST(FLOOR(t.production_year / 10) * 10 AS integer)
)
SELECT
    company_id,
    company_name,
    country_code,
    company_type_id,
    decade_start,
    movies_in_decade,
    ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY movies_in_decade DESC) AS rank_in_company
FROM movies_by_company_decade
WHERE movies_in_decade >= 5
ORDER BY company_id, movies_in_decade DESC
