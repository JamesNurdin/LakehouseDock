WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT cn.id) AS distinct_characters
    FROM cast_info ci
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY ci.movie_id
),
movie_runtime AS (
    SELECT
        mi.movie_id,
        TRY_CAST(mi.info AS INTEGER) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
)
SELECT
    kw.keyword,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(mc.distinct_characters) AS avg_characters_per_movie,
    AVG(mr.runtime_minutes) AS avg_runtime_minutes
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword kw ON kw.id = mk.keyword_id
LEFT JOIN movie_cast_counts mc ON mc.movie_id = t.id
LEFT JOIN movie_runtime mr ON mr.movie_id = t.id
WHERE kt.kind = 'movie'
  AND t.production_year > 2010
GROUP BY kw.keyword
ORDER BY movie_count DESC
LIMIT 10
