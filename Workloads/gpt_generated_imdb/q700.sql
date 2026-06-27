WITH keyword_movie_stats AS (
    SELECT
        k.keyword,
        t.kind_id,
        COUNT(DISTINCT t.id) AS distinct_movie_count,
        MIN(t.production_year) AS earliest_year,
        MAX(t.production_year) AS latest_year
    FROM
        keyword k
        JOIN movie_keyword mk ON mk.keyword_id = k.id
        JOIN title t ON mk.movie_id = t.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        k.keyword,
        t.kind_id
)
SELECT
    keyword,
    kind_id,
    distinct_movie_count,
    earliest_year,
    latest_year
FROM keyword_movie_stats
ORDER BY distinct_movie_count DESC
LIMIT 20
