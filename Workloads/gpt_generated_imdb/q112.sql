WITH us_company AS (
    SELECT 
        mc.movie_id,
        ct.kind AS company_type_kind
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    WHERE cn.country_code = 'US'
)
SELECT 
    CAST(t.production_year AS INTEGER) AS production_year,
    kt.kind AS title_kind,
    us.company_type_kind,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(mi_idx.note) AS avg_info_note
FROM us_company us
JOIN title t
    ON us.movie_id = t.id
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN movie_info_idx mi_idx
    ON t.id = mi_idx.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY 
    CAST(t.production_year AS INTEGER),
    kt.kind,
    us.company_type_kind
ORDER BY movie_count DESC
LIMIT 20
