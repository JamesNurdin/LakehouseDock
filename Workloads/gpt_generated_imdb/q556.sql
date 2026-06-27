WITH movie_cast AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_info ci ON ci.movie_id = t.id
    JOIN name n ON ci.person_id = n.id
    WHERE kt.kind = 'movie' AND t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_companies_agg AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_language AS (
    SELECT
        mi.movie_id,
        MAX(mi.info) AS language
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'language'
    GROUP BY mi.movie_id
)
SELECT
    mc.title,
    mc.production_year,
    mc.kind,
    mc.cast_count,
    co.company_count,
    kw.keywords,
    ml.language
FROM movie_cast mc
LEFT JOIN movie_companies_agg co ON co.movie_id = mc.movie_id
LEFT JOIN movie_keywords kw ON kw.movie_id = mc.movie_id
LEFT JOIN movie_language ml ON ml.movie_id = mc.movie_id
ORDER BY mc.cast_count DESC, mc.production_year DESC
LIMIT 10
