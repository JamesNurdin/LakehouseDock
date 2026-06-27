WITH info_per_movie AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS info_count
    FROM movie_info mi
    GROUP BY mi.movie_id
),
movie_keyword_info AS (
    SELECT
        t.production_year,
        k.keyword,
        t.id AS movie_id,
        ip.info_count
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN info_per_movie ip ON ip.movie_id = t.id
    WHERE t.production_year IS NOT NULL
)
SELECT
    production_year,
    keyword,
    COUNT(DISTINCT movie_id) AS movie_count,
    AVG(COALESCE(info_count, 0)) AS avg_info_per_movie
FROM movie_keyword_info
GROUP BY production_year, keyword
HAVING COUNT(DISTINCT movie_id) > 5
ORDER BY production_year, movie_count DESC
LIMIT 100
