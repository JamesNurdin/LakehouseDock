-- Top 3 companies by number of movie appearances for each company type
WITH company_counts AS (
    SELECT
        mc.company_id,
        ct.kind,
        COUNT(*) AS appearances
    FROM movie_companies mc
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    GROUP BY mc.company_id, ct.kind
),
ranked AS (
    SELECT
        company_id,
        kind,
        appearances,
        row_number() OVER (PARTITION BY kind ORDER BY appearances DESC) AS rn
    FROM company_counts
)
SELECT
    kind,
    company_id,
    appearances
FROM ranked
WHERE rn <= 3
ORDER BY kind, rn
