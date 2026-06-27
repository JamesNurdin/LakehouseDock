-- Top 10 US production companies by number of movies per year,
-- showing total keyword associations and average keywords per movie.
WITH company_movies AS (
    SELECT
        cn.name AS company_name,
        t.production_year AS production_year,
        t.id AS title_id
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
      AND cn.country_code = 'US'
      AND t.production_year IS NOT NULL
),
movie_counts AS (
    SELECT
        cm.company_name,
        cm.production_year,
        COUNT(DISTINCT cm.title_id) AS movie_count
    FROM company_movies cm
    GROUP BY cm.company_name, cm.production_year
),
keyword_counts AS (
    SELECT
        cm.company_name,
        cm.production_year,
        COUNT(mk.id) AS total_keyword_associations
    FROM company_movies cm
    JOIN movie_keyword mk
        ON cm.title_id = mk.movie_id
    GROUP BY cm.company_name, cm.production_year
)
SELECT
    mc.company_name,
    mc.production_year,
    mc.movie_count,
    kc.total_keyword_associations,
    CASE WHEN mc.movie_count = 0 THEN 0
         ELSE kc.total_keyword_associations * 1.0 / mc.movie_count
    END AS avg_keywords_per_movie
FROM movie_counts mc
JOIN keyword_counts kc
    ON mc.company_name = kc.company_name
   AND mc.production_year = kc.production_year
ORDER BY mc.movie_count DESC
LIMIT 10
