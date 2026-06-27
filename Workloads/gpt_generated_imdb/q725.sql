WITH movies_by_company_year AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        CAST(t.production_year AS integer) AS production_year,
        COUNT(DISTINCT t.id) AS movie_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title t ON mc.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE ct.kind = 'production'
      AND kt.kind = 'movie'
      AND t.production_year IS NOT NULL
    GROUP BY cn.id, cn.name, CAST(t.production_year AS integer)
),

top_years AS (
    SELECT
        company_id,
        company_name,
        production_year,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY movie_count DESC) AS rn
    FROM movies_by_company_year
),

company_year_movies AS (
    SELECT
        ty.company_id,
        ty.company_name,
        ty.production_year,
        ty.movie_count,
        t.id AS title_id
    FROM top_years ty
    JOIN movie_companies mc ON mc.company_id = ty.company_id
    JOIN title t ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE ty.rn <= 5
      AND ct.kind = 'production'
      AND kt.kind = 'movie'
      AND CAST(t.production_year AS integer) = ty.production_year
),

keyword_counts AS (
    SELECT
        cym.company_id,
        cym.company_name,
        cym.production_year,
        mk.keyword_id,
        COUNT(*) AS kw_count
    FROM company_year_movies cym
    JOIN movie_keyword mk ON mk.movie_id = cym.title_id
    GROUP BY cym.company_id, cym.company_name, cym.production_year, mk.keyword_id
),

top_keywords AS (
    SELECT
        company_id,
        company_name,
        production_year,
        keyword_id,
        kw_count,
        ROW_NUMBER() OVER (PARTITION BY company_id, production_year ORDER BY kw_count DESC) AS rn_kw
    FROM keyword_counts
)
SELECT
    tk.company_name,
    tk.production_year,
    mbc.movie_count,
    tk.keyword_id AS top_keyword_id,
    tk.kw_count AS top_keyword_count
FROM top_keywords tk
JOIN movies_by_company_year mbc
  ON mbc.company_id = tk.company_id
 AND mbc.production_year = tk.production_year
WHERE tk.rn_kw = 1
ORDER BY tk.company_name, tk.production_year DESC
