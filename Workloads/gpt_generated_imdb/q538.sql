WITH rating_per_movie AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
      AND mi.info IS NOT NULL
),
cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_type_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT ct.kind) AS company_type_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind AS kind,
    AVG(r.rating) AS avg_rating,
    cc.cast_count,
    kc.keyword_count,
    ctc.company_type_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN rating_per_movie r ON t.id = r.movie_id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN company_type_counts ctc ON t.id = ctc.movie_id
WHERE t.production_year IS NOT NULL
  AND t.production_year >= 2000
GROUP BY
    t.title,
    t.production_year,
    kt.kind,
    cc.cast_count,
    kc.keyword_count,
    ctc.company_type_count
HAVING AVG(r.rating) IS NOT NULL
ORDER BY avg_rating DESC
LIMIT 10
