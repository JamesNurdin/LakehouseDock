WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast,
        COUNT(DISTINCT ci.person_role_id) AS distinct_roles
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keywords
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS distinct_companies
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
rating_per_movie AS (
    SELECT
        mi.movie_id,
        AVG(TRY_CAST(mi.info AS DOUBLE)) AS avg_rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
),
movie_agg AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        kt.kind AS movie_kind,
        COALESCE(cc.distinct_cast, 0) AS cast_cnt,
        COALESCE(kc.distinct_keywords, 0) AS keyword_cnt,
        COALESCE(comc.distinct_companies, 0) AS company_cnt,
        r.avg_rating
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_counts cc   ON t.id = cc.movie_id
    LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
    LEFT JOIN company_counts comc ON t.id = comc.movie_id
    LEFT JOIN rating_per_movie r   ON t.id = r.movie_id
)
SELECT
    movie_kind,
    production_year,
    COUNT(*)                         AS movies_in_year,
    AVG(cast_cnt)                    AS avg_cast_per_movie,
    AVG(keyword_cnt)                 AS avg_keywords_per_movie,
    AVG(company_cnt)                 AS avg_companies_per_movie,
    AVG(avg_rating)                  AS avg_rating_per_movie
FROM movie_agg
WHERE production_year IS NOT NULL
GROUP BY movie_kind, production_year
ORDER BY movies_in_year DESC
LIMIT 20
