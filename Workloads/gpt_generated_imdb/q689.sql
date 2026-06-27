WITH runtime_info AS (
    SELECT mi.movie_id,
           CAST(mi.info AS DOUBLE) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_member_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_stats AS (
    SELECT t.id AS movie_id,
           t.kind_id,
           t.production_year,
           ri.runtime_minutes,
           cc.cast_member_count
    FROM title t
    LEFT JOIN runtime_info ri ON ri.movie_id = t.id
    LEFT JOIN cast_counts cc ON cc.movie_id = t.id
    WHERE t.production_year >= 2000
)
SELECT
    mk.keyword_id,
    kt.kind AS kind,
    COUNT(DISTINCT ms.movie_id) AS movie_count,
    AVG(ms.runtime_minutes) AS avg_runtime_minutes,
    AVG(ms.cast_member_count) AS avg_cast_members_per_movie
FROM movie_keyword mk
JOIN movie_stats ms ON mk.movie_id = ms.movie_id
JOIN kind_type kt ON ms.kind_id = kt.id
GROUP BY mk.keyword_id, kt.kind
ORDER BY movie_count DESC
LIMIT 20
