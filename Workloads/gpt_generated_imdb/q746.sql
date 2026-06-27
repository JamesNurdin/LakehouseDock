WITH cast_per_movie AS (
    SELECT
        ci.movie_id,
        COUNT(*) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_per_movie AS (
    SELECT
        mk.movie_id,
        COUNT(*) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_per_movie AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_details AS (
    SELECT
        t.id AS movie_id,
        kt.kind AS kind,
        COALESCE(cpm.cast_cnt, 0)      AS cast_cnt,
        COALESCE(kpm.keyword_cnt, 0)   AS keyword_cnt,
        COALESCE(cpm2.company_cnt, 0)  AS company_cnt,
        t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_per_movie cpm   ON t.id = cpm.movie_id
    LEFT JOIN keyword_per_movie kpm ON t.id = kpm.movie_id
    LEFT JOIN company_per_movie cpm2 ON t.id = cpm2.movie_id
    WHERE t.production_year BETWEEN 2000 AND 2020
)
SELECT
    md.kind,
    COUNT(*)                         AS movie_count,
    AVG(md.cast_cnt)                 AS avg_cast_per_movie,
    AVG(md.keyword_cnt)              AS avg_keywords_per_movie,
    AVG(md.company_cnt)              AS avg_companies_per_movie
FROM movie_details md
GROUP BY md.kind
ORDER BY movie_count DESC
LIMIT 10
