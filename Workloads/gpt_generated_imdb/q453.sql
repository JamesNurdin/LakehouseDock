WITH movie_metrics AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
company_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        cn.name AS company_name,
        COUNT(DISTINCT t.id) AS movie_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production company'
      AND t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind, cn.name
),
top_company AS (
    SELECT
        production_year,
        kind,
        company_name,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY production_year, kind ORDER BY movie_count DESC) AS rn
    FROM company_counts
)
SELECT
    mm.production_year,
    mm.kind,
    COUNT(*) AS total_movies,
    AVG(mm.cast_count) AS avg_cast_per_movie,
    AVG(mm.keyword_count) AS avg_keywords_per_movie,
    tc.company_name AS top_production_company,
    tc.movie_count AS top_company_movie_count
FROM movie_metrics mm
LEFT JOIN top_company tc
    ON mm.production_year = tc.production_year
   AND mm.kind = tc.kind
   AND tc.rn = 1
GROUP BY mm.production_year, mm.kind, tc.company_name, tc.movie_count
ORDER BY mm.production_year DESC, total_movies DESC
LIMIT 20
