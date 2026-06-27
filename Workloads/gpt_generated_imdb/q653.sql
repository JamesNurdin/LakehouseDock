WITH company_movie_counts AS (
    SELECT 
        mc.company_id,
        ct.kind,
        COUNT(DISTINCT mc.movie_id) AS movies_per_company
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE mc.note LIKE '%producer%'
    GROUP BY mc.company_id, ct.kind
),
ranked_companies AS (
    SELECT 
        company_id,
        kind,
        movies_per_company,
        RANK() OVER (PARTITION BY kind ORDER BY movies_per_company DESC) AS rnk
    FROM company_movie_counts
)
SELECT 
    kind,
    company_id,
    movies_per_company
FROM ranked_companies
WHERE rnk <= 5
ORDER BY kind, movies_per_company DESC
