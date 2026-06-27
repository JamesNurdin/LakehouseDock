WITH cast_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
company_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT company_id) AS company_count
    FROM movie_companies
    GROUP BY movie_id
),
keyword_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
),
movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        t.kind_id,
        COALESCE(cc.cast_count, 0) AS cast_count,
        COALESCE(compc.company_count, 0) AS company_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM title t
    LEFT JOIN cast_counts cc ON cc.movie_id = t.id
    LEFT JOIN company_counts compc ON compc.movie_id = t.id
    LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
),
per_year_stats AS (
    SELECT
        production_year,
        kind_id,
        COUNT(*) AS movie_count,
        AVG(cast_count) AS avg_cast_per_movie,
        AVG(company_count) AS avg_companies_per_movie,
        AVG(keyword_count) AS avg_keywords_per_movie
    FROM movie_stats
    GROUP BY production_year, kind_id
),
company_type_per_year AS (
    SELECT
        t.production_year,
        ct.kind AS company_type_kind,
        COUNT(DISTINCT mc.movie_id) AS movies_with_company_type
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, ct.kind
),
top_company_type_per_year AS (
    SELECT
        production_year,
        company_type_kind
    FROM (
        SELECT
            production_year,
            company_type_kind,
            movies_with_company_type,
            ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movies_with_company_type DESC) AS rn
        FROM company_type_per_year
    )
    WHERE rn = 1
)
SELECT
    pys.production_year,
    pys.kind_id,
    pys.movie_count,
    pys.avg_cast_per_movie,
    pys.avg_companies_per_movie,
    pys.avg_keywords_per_movie,
    tct.company_type_kind AS top_company_type_kind
FROM per_year_stats pys
LEFT JOIN top_company_type_per_year tct ON pys.production_year = tct.production_year
ORDER BY pys.production_year DESC, pys.kind_id
