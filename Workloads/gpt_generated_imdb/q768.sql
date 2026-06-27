WITH kw_counts AS (
    SELECT movie_id,
           count(*) AS kw_cnt
    FROM movie_keyword
    GROUP BY movie_id
),
comp_counts AS (
    SELECT movie_id,
           count(DISTINCT company_id) AS comp_cnt
    FROM movie_companies
    GROUP BY movie_id
)
SELECT
    name.id AS person_id,
    name.name AS person_name,
    kind_type.kind AS title_kind,
    count(DISTINCT title.id) AS total_titles,
    min(title.production_year) AS first_year,
    max(title.production_year) AS last_year,
    avg(COALESCE(kw_counts.kw_cnt, 0)) AS avg_keywords_per_title,
    avg(COALESCE(comp_counts.comp_cnt, 0)) AS avg_companies_per_title
FROM cast_info
JOIN name ON cast_info.person_id = name.id
JOIN title ON cast_info.movie_id = title.id
JOIN kind_type ON title.kind_id = kind_type.id
LEFT JOIN kw_counts ON title.id = kw_counts.movie_id
LEFT JOIN comp_counts ON title.id = comp_counts.movie_id
WHERE title.production_year IS NOT NULL
GROUP BY name.id, name.name, kind_type.kind
ORDER BY total_titles DESC
LIMIT 20
