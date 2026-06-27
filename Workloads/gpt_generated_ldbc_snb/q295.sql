-- Analytical query: number of organisations per parent place and organisation type
WITH org_loc AS (
    SELECT
        o.id AS org_id,
        o.type AS org_type,
        o.name AS org_name,
        o.url AS org_url,
        p.id AS loc_place_id,
        p.name AS loc_place_name,
        p.type AS loc_place_type,
        p.part_of_place_id AS loc_parent_place_id
    FROM organisation AS o
    JOIN place AS p
        ON o.location_place_id = p.id
),
parent_place AS (
    SELECT
        ol.org_id,
        ol.org_type,
        ol.loc_place_id,
        ol.loc_place_name,
        ol.loc_place_type,
        parent.id   AS parent_place_id,
        parent.name AS parent_place_name,
        parent.type AS parent_place_type
    FROM org_loc AS ol
    LEFT JOIN place AS parent
        ON ol.loc_parent_place_id = parent.id
)
SELECT
    pp.parent_place_name,
    pp.parent_place_type,
    pp.org_type,
    COUNT(DISTINCT pp.org_id) AS org_count
FROM parent_place AS pp
GROUP BY
    pp.parent_place_name,
    pp.parent_place_type,
    pp.org_type
ORDER BY
    org_count DESC,
    pp.parent_place_name
