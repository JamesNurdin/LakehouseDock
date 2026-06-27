/*
  Average runtime (in minutes) of movies per keyword and kind, for keywords that appear
  in at least 10 movies. The query joins title → kind_type, title → movie_keyword → keyword,
  and title → movie_info (filtered to the 'runtime' info_type). It aggregates by keyword
  and kind, counting movies and computing the average runtime.
*/
WITH keyword_runtime AS (
    SELECT
        k.keyword,
        kt.kind,
        CAST(mi.info AS double) AS runtime_minutes
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    JOIN movie_keyword mk
        ON mk.movie_id = t.id
    JOIN keyword k
        ON k.id = mk.keyword_id
    JOIN movie_info mi
        ON mi.movie_id = t.id
    JOIN info_type it
        ON it.id = mi.info_type_id
    WHERE it.info = 'runtime'
      AND TRY_CAST(mi.info AS double) IS NOT NULL
)
SELECT
    keyword,
    kind,
    COUNT(*) AS movie_count,
    AVG(runtime_minutes) AS avg_runtime_minutes
FROM keyword_runtime
GROUP BY keyword, kind
HAVING COUNT(*) >= 10
ORDER BY movie_count DESC, keyword
LIMIT 20
