WITH per_title AS (
    SELECT
        t.id AS title_id,
        t.production_year,
        kt.kind AS kind_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN cn.id END) AS prod_company_count,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN company_type ct
        ON mc.company_type_id = ct.id
    LEFT JOIN company_name cn
        ON mc.company_id = cn.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN keyword k
        ON k.id = mk.keyword_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.production_year, kt.kind
)
SELECT
    production_year,
    kind_name,
    COUNT(*) AS num_titles,
    SUM(cast_count) AS total_cast_members,
    AVG(cast_count) AS avg_cast_per_title,
    SUM(prod_company_count) AS total_production_companies,
    AVG(prod_company_count) AS avg_production_companies_per_title,
    SUM(keyword_count) AS total_keywords,
    AVG(keyword_count) AS avg_keywords_per_title
FROM per_title
GROUP BY production_year, kind_name
ORDER BY production_year, kind_name
