WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_cnt
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_aggregates AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COALESCE(cc.cast_cnt, 0) AS cast_cnt,
        COALESCE(kc.keyword_cnt, 0) AS keyword_cnt,
        COALESCE(compc.company_cnt, 0) AS company_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_counts cc ON cc.movie_id = t.id
    LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
    LEFT JOIN company_counts compc ON compc.movie_id = t.id
)
SELECT
    ma.kind,
    COUNT(*) AS movie_count,
    AVG(ma.cast_cnt) AS avg_cast_per_movie,
    AVG(ma.keyword_cnt) AS avg_keywords_per_movie,
    AVG(ma.company_cnt) AS avg_companies_per_movie
FROM movie_aggregates ma
GROUP BY ma.kind
ORDER BY avg_cast_per_movie DESC
