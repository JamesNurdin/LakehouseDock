WITH company_movie_counts AS (
    SELECT
        ct.kind AS company_type,
        cn.id AS company_id,
        cn.name AS company_name,
        COUNT(DISTINCT t.id) AS movie_cnt
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title t ON mc.movie_id = t.id
    GROUP BY ct.kind, cn.id, cn.name
),
ranked_companies AS (
    SELECT
        company_type,
        company_id,
        company_name,
        movie_cnt,
        ROW_NUMBER() OVER (PARTITION BY company_type ORDER BY movie_cnt DESC) AS rn,
        SUM(movie_cnt) OVER (PARTITION BY company_type) AS total_movies_by_type
    FROM company_movie_counts
),
top_companies AS (
    SELECT
        company_type,
        company_name,
        movie_cnt,
        total_movies_by_type,
        CAST(movie_cnt AS double) / total_movies_by_type AS proportion_of_type
    FROM ranked_companies
    WHERE rn <= 5
)
SELECT
    company_type,
    company_name,
    movie_cnt,
    total_movies_by_type,
    proportion_of_type
FROM top_companies
ORDER BY company_type, movie_cnt DESC
