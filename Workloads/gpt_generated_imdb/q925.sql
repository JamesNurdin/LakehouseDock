WITH title_info AS (
    SELECT
        movie_id,
        AVG(note) AS avg_note,
        COUNT(DISTINCT info_type_id) AS distinct_info_type_cnt
    FROM movie_info_idx
    GROUP BY movie_id
),
title_company AS (
    SELECT
        mc.movie_id,
        mc.company_id,
        ct.kind AS company_type,
        cn.country_code
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
)
SELECT
    t.production_year,
    tc.company_type,
    kt.kind AS title_kind,
    COUNT(DISTINCT t.id) AS num_titles,
    COUNT(DISTINCT tc.company_id) AS num_companies,
    AVG(ti.avg_note) AS avg_info_note,
    MAX(ti.distinct_info_type_cnt) AS distinct_info_type_cnt,
    COUNT(DISTINCT tc.country_code) AS num_countries
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN title_info ti ON ti.movie_id = t.id
JOIN title_company tc ON tc.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, tc.company_type, kt.kind
ORDER BY t.production_year DESC, tc.company_type, kt.kind
