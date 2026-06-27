WITH
    movies_per_year_kind AS (
        SELECT
            t.production_year,
            kt.kind AS kind,
            COUNT(DISTINCT t.id) AS movie_count
        FROM title t
        JOIN kind_type kt ON t.kind_id = kt.id
        WHERE t.production_year >= 2000
          AND kt.kind = 'movie'
        GROUP BY t.production_year, kt.kind
    ),
    cast_per_movie AS (
        SELECT
            ci.movie_id,
            COUNT(DISTINCT ci.person_id) AS cast_count
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    cast_agg AS (
        SELECT
            t.production_year,
            kt.kind,
            AVG(cpm.cast_count) AS avg_cast_per_movie
        FROM title t
        JOIN kind_type kt ON t.kind_id = kt.id
        JOIN cast_per_movie cpm ON t.id = cpm.movie_id
        WHERE t.production_year >= 2000
          AND kt.kind = 'movie'
        GROUP BY t.production_year, kt.kind
    ),
    prod_companies_per_movie AS (
        SELECT
            mc.movie_id,
            COUNT(DISTINCT cn.id) AS prod_company_count
        FROM movie_companies mc
        JOIN company_type ct ON mc.company_type_id = ct.id
        JOIN company_name cn ON mc.company_id = cn.id
        WHERE ct.kind = 'production'
        GROUP BY mc.movie_id
    ),
    prod_companies_agg AS (
        SELECT
            t.production_year,
            kt.kind,
            AVG(pcm.prod_company_count) AS avg_prod_companies
        FROM title t
        JOIN kind_type kt ON t.kind_id = kt.id
        JOIN prod_companies_per_movie pcm ON t.id = pcm.movie_id
        WHERE t.production_year >= 2000
          AND kt.kind = 'movie'
        GROUP BY t.production_year, kt.kind
    ),
    keyword_counts_per_year AS (
        SELECT
            t.production_year,
            k.keyword,
            COUNT(DISTINCT mk.movie_id) AS keyword_movie_count
        FROM title t
        JOIN kind_type kt ON t.kind_id = kt.id
        JOIN movie_keyword mk ON t.id = mk.movie_id
        JOIN keyword k ON mk.keyword_id = k.id
        WHERE t.production_year >= 2000
          AND kt.kind = 'movie'
        GROUP BY t.production_year, k.keyword
    ),
    top_keyword_per_year AS (
        SELECT
            production_year,
            keyword,
            keyword_movie_count
        FROM (
            SELECT
                production_year,
                keyword,
                keyword_movie_count,
                ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY keyword_movie_count DESC) AS rn
            FROM keyword_counts_per_year
        ) sub
        WHERE rn = 1
    )
SELECT
    mp.production_year,
    mp.kind,
    mp.movie_count,
    ca.avg_cast_per_movie,
    pc.avg_prod_companies,
    tk.keyword AS top_keyword,
    tk.keyword_movie_count AS top_keyword_movie_count
FROM movies_per_year_kind mp
JOIN cast_agg ca
  ON mp.production_year = ca.production_year
 AND mp.kind = ca.kind
JOIN prod_companies_agg pc
  ON mp.production_year = pc.production_year
 AND mp.kind = pc.kind
LEFT JOIN top_keyword_per_year tk
  ON mp.production_year = tk.production_year
ORDER BY mp.production_year DESC, mp.movie_count DESC
