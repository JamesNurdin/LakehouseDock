WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT cn.id) AS distinct_characters
    FROM cast_info ci
    LEFT JOIN char_name cn
        ON ci.person_role_id = cn.id
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
rating_info AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS DOUBLE) AS rating
    FROM movie_info mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
)
SELECT
    t.title,
    t.production_year,
    kt.kind,
    cc.cast_count,
    cc.distinct_characters,
    co.company_count,
    kw.keyword_count,
    r.rating
FROM title t
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN cast_counts cc
    ON t.id = cc.movie_id
LEFT JOIN company_counts co
    ON t.id = co.movie_id
LEFT JOIN keyword_counts kw
    ON t.id = kw.movie_id
LEFT JOIN rating_info r
    ON t.id = r.movie_id
WHERE t.production_year >= 2000
ORDER BY cc.cast_count DESC
LIMIT 10
