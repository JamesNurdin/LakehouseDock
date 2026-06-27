WITH company_movie_counts AS (
    SELECT
        mc.company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        t.production_year,
        COUNT(DISTINCT t.id) AS movie_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title t ON mc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY mc.company_id, cn.name, ct.kind, t.production_year
),
ranked_companies AS (
    SELECT
        company_id,
        company_name,
        company_type,
        production_year,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rn
    FROM company_movie_counts
),
company_top_keyword AS (
    SELECT
        mc.company_id,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT t.id) AS keyword_movie_count,
        ROW_NUMBER() OVER (PARTITION BY mc.company_id, t.production_year ORDER BY COUNT(DISTINCT t.id) DESC) AS kw_rn
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year IS NOT NULL
    GROUP BY mc.company_id, t.production_year, k.keyword
)
SELECT
    rc.production_year,
    rc.company_name,
    rc.company_type,
    rc.movie_count,
    kw.keyword,
    kw.keyword_movie_count
FROM ranked_companies rc
JOIN company_top_keyword kw
    ON rc.company_id = kw.company_id
   AND rc.production_year = kw.production_year
   AND kw.kw_rn = 1
WHERE rc.rn = 1
ORDER BY rc.production_year, rc.movie_count DESC
