WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_company_counts AS (
    SELECT
        mc.movie_id,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, ct.kind
),
movie_company_top AS (
    SELECT
        movie_id,
        company_type,
        ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY company_count DESC) AS rn
    FROM movie_company_counts
)
SELECT
    mc.movie_id,
    mc.title,
    mc.production_year,
    mc.kind,
    mc.cast_count,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    ctop.company_type AS top_company_type
FROM movie_cast_counts mc
LEFT JOIN movie_keyword_counts mkc ON mkc.movie_id = mc.movie_id
LEFT JOIN movie_company_top ctop ON ctop.movie_id = mc.movie_id AND ctop.rn = 1
ORDER BY mc.cast_count DESC
LIMIT 10
