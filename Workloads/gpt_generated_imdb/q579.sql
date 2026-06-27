WITH movie_counts AS (
    SELECT
        t.id AS movie_id,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_cnt,
        COUNT(DISTINCT k.id) AS kw_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year > 2000
    GROUP BY t.id, kt.kind
)
SELECT
    kind,
    COUNT(*) AS movie_cnt,
    AVG(cast_cnt) AS avg_cast_per_movie,
    AVG(kw_cnt) AS avg_keywords_per_movie
FROM movie_counts
GROUP BY kind
ORDER BY movie_cnt DESC
LIMIT 10
