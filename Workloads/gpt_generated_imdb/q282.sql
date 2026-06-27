/*
  Analytical query: For each combination of company type and country, compute the number of movies produced per production year
  and the average number of distinct keywords associated with those movies.
  Only companies with at least 5 movies in a given year are shown.
*/
WITH keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id  -- valid join rule: movie_keyword.movie_id = title.id
    GROUP BY mk.movie_id
),
movie_company_details AS (
    SELECT
        mc.movie_id,
        ct.kind AS company_type,
        cn.country_code,
        t.production_year
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id               -- valid join rule
    JOIN company_name cn ON mc.company_id = cn.id                     -- valid join rule
    JOIN title t ON mc.movie_id = t.id                               -- valid join rule
    WHERE t.production_year IS NOT NULL
)
SELECT
    mcd.company_type,
    mcd.country_code,
    CAST(mcd.production_year AS INTEGER) AS production_year,
    COUNT(DISTINCT mcd.movie_id) AS movie_cnt,
    AVG(COALESCE(kc.kw_cnt, 0)) AS avg_keywords_per_movie
FROM movie_company_details mcd
LEFT JOIN keyword_counts kc ON mcd.movie_id = kc.movie_id
GROUP BY
    mcd.company_type,
    mcd.country_code,
    CAST(mcd.production_year AS INTEGER)
HAVING COUNT(DISTINCT mcd.movie_id) >= 5
ORDER BY movie_cnt DESC
LIMIT 50
