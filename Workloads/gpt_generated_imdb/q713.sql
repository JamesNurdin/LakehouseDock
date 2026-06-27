WITH movies_agg AS (
    SELECT
        ci.person_id AS person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MIN(t.production_year) AS earliest_year,
        MAX(t.production_year) AS latest_year
    FROM cast_info ci
    JOIN title t
        ON ci.movie_id = t.id
    GROUP BY ci.person_id
),
aka_agg AS (
    SELECT
        an.person_id AS person_id,
        COUNT(DISTINCT an.id) AS alt_name_count
    FROM aka_name an
    GROUP BY an.person_id
),
info_agg AS (
    SELECT
        pi.person_id AS person_id,
        COUNT(DISTINCT pi.id) AS info_count
    FROM person_info pi
    GROUP BY pi.person_id
)
SELECT
    n.id AS person_id,
    n.name,
    n.gender,
    COALESCE(m.movie_count, 0) AS movie_count,
    m.earliest_year,
    m.latest_year,
    COALESCE(a.alt_name_count, 0) AS alt_name_count,
    COALESCE(i.info_count, 0) AS info_count
FROM name n
LEFT JOIN movies_agg m
    ON n.id = m.person_id
LEFT JOIN aka_agg a
    ON n.id = a.person_id
LEFT JOIN info_agg i
    ON n.id = i.person_id
WHERE n.gender = 'M'
ORDER BY movie_count DESC
LIMIT 100
