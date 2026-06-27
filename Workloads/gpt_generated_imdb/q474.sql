WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_production_companies AS (
    SELECT
        t.id AS movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS production_companies
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON ct.id = mc.company_type_id
    LEFT JOIN company_name cn ON cn.id = mc.company_id
    WHERE ct.kind = 'production'
    GROUP BY t.id
),
movie_info_stats AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM title t
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    GROUP BY t.id
)
SELECT
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.kind,
    ms.cast_count,
    ms.keyword_count,
    mis.info_type_count,
    pc.production_companies
FROM movie_stats ms
LEFT JOIN movie_production_companies pc ON pc.movie_id = ms.movie_id
LEFT JOIN movie_info_stats mis ON mis.movie_id = ms.movie_id
ORDER BY ms.cast_count DESC, ms.keyword_count DESC
LIMIT 10
