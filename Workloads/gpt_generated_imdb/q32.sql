WITH filtered_titles AS (
    SELECT
        t.id AS title_id,
        t.production_year
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2000
),
company_movie_counts AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        cn.country_code,
        COUNT(DISTINCT ft.title_id) AS movie_count,
        MIN(ft.production_year) AS earliest_year,
        MAX(ft.production_year) AS latest_year,
        AVG(ft.production_year) AS avg_year
    FROM filtered_titles ft
    JOIN movie_companies mc
        ON mc.movie_id = ft.title_id
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY cn.id, cn.name, cn.country_code
)
SELECT
    cmc.company_name,
    cmc.country_code,
    cmc.movie_count,
    cmc.earliest_year,
    cmc.latest_year,
    cmc.avg_year,
    RANK() OVER (ORDER BY cmc.movie_count DESC) AS rank_by_movies
FROM company_movie_counts cmc
ORDER BY cmc.movie_count DESC
LIMIT 20
