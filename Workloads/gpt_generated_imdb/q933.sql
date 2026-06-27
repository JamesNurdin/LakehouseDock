WITH movie_financials AS (
    SELECT
        mi.movie_id,
        SUM(CASE WHEN it.info = 'budget' THEN CAST(mi.info AS double) ELSE 0 END) AS total_budget,
        SUM(CASE WHEN it.info = 'gross'  THEN CAST(mi.info AS double) ELSE 0 END) AS total_gross
    FROM movie_info_idx mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
),
movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_char_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_role_id) AS char_count
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind,
    COALESCE(cc.cast_count, 0)      AS cast_count,
    COALESCE(compc.company_count, 0) AS company_count,
    COALESCE(chc.char_count, 0)      AS char_count,
    COALESCE(fin.total_budget, 0)   AS total_budget,
    COALESCE(fin.total_gross, 0)    AS total_gross
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_cast_counts cc     ON cc.movie_id = t.id
LEFT JOIN movie_company_counts compc ON compc.movie_id = t.id
LEFT JOIN movie_char_counts chc    ON chc.movie_id = t.id
LEFT JOIN movie_financials fin     ON fin.movie_id = t.id
WHERE kt.kind = 'movie'
ORDER BY total_gross DESC
LIMIT 10
