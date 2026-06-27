WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_company_type_counts AS (
    SELECT
        mc.movie_id,
        mc.company_type_id,
        COUNT(DISTINCT mc.company_id) AS company_type_count
    FROM movie_companies mc
    GROUP BY mc.movie_id, mc.company_type_id
)
SELECT
    kt.kind AS title_kind,
    ct.kind AS company_type,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(mctc.company_type_count, 0)) AS avg_company_type_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
JOIN movie_companies mc ON mc.movie_id = t.id
JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN movie_cast_counts cc ON cc.movie_id = t.id
LEFT JOIN movie_company_type_counts mctc
    ON mctc.movie_id = t.id AND mctc.company_type_id = ct.id
WHERE t.production_year >= 2000
GROUP BY kt.kind, ct.kind
ORDER BY kt.kind, ct.kind
