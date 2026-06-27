WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS genre,
        COALESCE(cast_counts.cast_count, 0) AS cast_count,
        COALESCE(kw_counts.keyword_count, 0) AS keyword_count,
        COALESCE(comp_counts.company_count, 0) AS company_count,
        COALESCE(prod_comp_counts.prod_company_count, 0) AS prod_company_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN (
        SELECT ci.movie_id, COUNT(DISTINCT ci.person_id) AS cast_count
        FROM cast_info ci
        GROUP BY ci.movie_id
    ) cast_counts ON cast_counts.movie_id = t.id
    LEFT JOIN (
        SELECT mk.movie_id, COUNT(DISTINCT mk.keyword_id) AS keyword_count
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    ) kw_counts ON kw_counts.movie_id = t.id
    LEFT JOIN (
        SELECT mc.movie_id, COUNT(DISTINCT mc.company_id) AS company_count
        FROM movie_companies mc
        GROUP BY mc.movie_id
    ) comp_counts ON comp_counts.movie_id = t.id
    LEFT JOIN (
        SELECT mc.movie_id, COUNT(DISTINCT mc.company_id) AS prod_company_count
        FROM movie_companies mc
        JOIN company_type ct ON mc.company_type_id = ct.id
        WHERE ct.kind = 'production'
        GROUP BY mc.movie_id
    ) prod_comp_counts ON prod_comp_counts.movie_id = t.id
    WHERE t.production_year IS NOT NULL
)
SELECT
    md.production_year,
    md.genre,
    COUNT(DISTINCT md.movie_id) AS num_movies,
    SUM(md.cast_count) AS total_cast_members,
    SUM(md.keyword_count) AS total_keywords,
    SUM(md.company_count) AS total_companies,
    SUM(md.prod_company_count) AS total_production_companies
FROM movie_details md
GROUP BY md.production_year, md.genre
HAVING COUNT(DISTINCT md.movie_id) >= 10
ORDER BY md.production_year DESC, md.genre
