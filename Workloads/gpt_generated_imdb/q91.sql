WITH cast_gender_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) FILTER (WHERE n.gender = 'M') AS male_cast_cnt,
        COUNT(DISTINCT ci.person_id) FILTER (WHERE n.gender = 'F') AS female_cast_cnt,
        COUNT(DISTINCT ci.person_id) AS total_cast_cnt
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_cnt,
        COUNT(DISTINCT ct.kind) AS distinct_company_type_cnt
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS genre,
        COALESCE(cgc.total_cast_cnt, 0) AS total_cast_cnt,
        COALESCE(cgc.male_cast_cnt, 0) AS male_cast_cnt,
        COALESCE(cgc.female_cast_cnt, 0) AS female_cast_cnt,
        COALESCE(cc.company_cnt, 0) AS company_cnt,
        COALESCE(cc.distinct_company_type_cnt, 0) AS distinct_company_type_cnt,
        COALESCE(kc.keyword_cnt, 0) AS keyword_cnt,
        (COALESCE(cgc.total_cast_cnt, 0) + COALESCE(cc.company_cnt, 0) + COALESCE(kc.keyword_cnt, 0)) AS total_score
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_gender_counts cgc ON t.id = cgc.movie_id
    LEFT JOIN company_counts cc ON t.id = cc.movie_id
    LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
    WHERE t.production_year >= 2000
)
SELECT
    md.genre,
    md.title,
    md.production_year,
    md.total_cast_cnt,
    md.male_cast_cnt,
    md.female_cast_cnt,
    md.company_cnt,
    md.distinct_company_type_cnt,
    md.keyword_cnt,
    md.total_score,
    ROW_NUMBER() OVER (PARTITION BY md.genre ORDER BY md.total_score DESC) AS genre_rank
FROM movie_details md
WHERE md.genre IS NOT NULL
ORDER BY md.genre, genre_rank
LIMIT 100
