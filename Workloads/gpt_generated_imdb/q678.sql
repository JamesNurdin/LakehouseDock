WITH cast_per_movie AS (
    SELECT
        movie_id,
        count(DISTINCT person_id) AS cast_size
    FROM cast_info
    GROUP BY movie_id
),
movie_stats AS (
    SELECT
        t.production_year,
        kt.kind,
        count(DISTINCT t.id) AS total_movies,
        avg(COALESCE(cpm.cast_size, 0)) AS avg_cast_size
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_per_movie cpm ON t.id = cpm.movie_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind
),
keyword_stats AS (
    SELECT
        t.production_year,
        kt.kind,
        count(DISTINCT mk.keyword_id) AS distinct_keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind
)
SELECT
    ms.production_year,
    ms.kind,
    ms.total_movies,
    ms.avg_cast_size,
    ks.distinct_keyword_count
FROM movie_stats ms
LEFT JOIN keyword_stats ks
    ON ms.production_year = ks.production_year
   AND ms.kind = ks.kind
ORDER BY ms.total_movies DESC
LIMIT 20
