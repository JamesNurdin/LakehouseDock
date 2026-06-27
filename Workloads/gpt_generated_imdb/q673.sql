WITH movie_cast AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id, t.production_year, kt.kind
),
movie_keywords AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id
),
movie_prod_companies AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN cn.id END) AS prod_company_count
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY t.id
),
movie_info_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(*) AS info_entry_count
    FROM title t
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY t.id
)
SELECT
    mc.production_year,
    mc.kind,
    COUNT(*) AS movie_count,
    AVG(mc.cast_count) AS avg_cast_per_movie,
    AVG(mk.keyword_count) AS avg_keywords_per_movie,
    AVG(pc.prod_company_count) AS avg_production_companies_per_movie,
    AVG(mi.info_entry_count) AS avg_info_entries_per_movie
FROM movie_cast mc
JOIN movie_keywords mk ON mk.movie_id = mc.movie_id
JOIN movie_prod_companies pc ON pc.movie_id = mc.movie_id
JOIN movie_info_counts mi ON mi.movie_id = mc.movie_id
WHERE mc.production_year IS NOT NULL
GROUP BY mc.production_year, mc.kind
ORDER BY mc.production_year, mc.kind
