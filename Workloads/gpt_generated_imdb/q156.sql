WITH cast_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count,
           COUNT(DISTINCT ct.kind)      AS company_type_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
)
SELECT
    k.kind AS kind_name,
    CAST(floor(t.production_year / 10) * 10 AS integer) AS decade,
    COUNT(*) AS movie_count,
    AVG(t.production_year) AS avg_production_year,
    SUM(COALESCE(cc.cast_count, 0)) AS total_cast_members,
    SUM(COALESCE(compc.company_count, 0)) AS total_companies,
    SUM(COALESCE(kwc.keyword_count, 0)) AS total_keywords
FROM title t
JOIN kind_type k ON t.kind_id = k.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN company_counts compc ON t.id = compc.movie_id
LEFT JOIN keyword_counts kwc ON t.id = kwc.movie_id
WHERE t.production_year >= 2000
GROUP BY k.kind,
         CAST(floor(t.production_year / 10) * 10 AS integer)
ORDER BY movie_count DESC
LIMIT 100
