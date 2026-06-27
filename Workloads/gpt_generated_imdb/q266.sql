WITH cast_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id
),
keyword_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id
),
company_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id
),
aka_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ak.id) AS aka_name_count
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN name n ON n.id = ci.person_id
    LEFT JOIN aka_name ak ON ak.person_id = n.id
    GROUP BY t.id
)
SELECT
    t.title,
    t.production_year,
    kt.kind,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(compc.company_count, 0) AS company_count,
    COALESCE(ac.aka_name_count, 0) AS aka_name_count,
    ROW_NUMBER() OVER (ORDER BY COALESCE(cc.cast_count, 0) DESC) AS cast_rank
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN company_counts compc ON compc.movie_id = t.id
LEFT JOIN aka_counts ac ON ac.movie_id = t.id
WHERE kt.kind = 'movie' AND t.production_year >= 2000
ORDER BY cast_count DESC
LIMIT 10
