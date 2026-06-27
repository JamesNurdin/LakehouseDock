-- Analytical query: number of titles, average cast size and average keyword count per company type and title kind
WITH per_title AS (
    SELECT
        t.id AS title_id,
        kt.kind AS title_kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id, kt.kind
)
SELECT
    ct.kind AS company_type,
    pt.title_kind,
    COUNT(DISTINCT pt.title_id) AS title_count,
    AVG(pt.cast_count) AS avg_cast_per_title,
    AVG(pt.keyword_count) AS avg_keywords_per_title
FROM per_title pt
JOIN movie_companies mc ON mc.movie_id = pt.title_id
JOIN company_type ct ON mc.company_type_id = ct.id
GROUP BY ct.kind, pt.title_kind
ORDER BY title_count DESC
LIMIT 20
