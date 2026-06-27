WITH org_comments AS (
    SELECT
        o.id AS org_id,
        o.name AS org_name,
        o.type AS org_type,
        p_region.name AS region_name,
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id AS comment_creator_id
    FROM organisation o
    JOIN place p_org ON o.location_place_id = p_org.id
    LEFT JOIN place p_region ON p_org.part_of_place_id = p_region.id
    JOIN post p ON p.location_country_id = p_org.id
    JOIN comment c ON c.parent_post_id = p.id
)
SELECT
    org_id,
    org_name,
    org_type,
    region_name,
    COUNT(comment_id) AS total_comments,
    SUM(comment_length) AS total_comment_length,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT comment_creator_id) AS distinct_commenters
FROM org_comments
GROUP BY org_id, org_name, org_type, region_name
ORDER BY total_comments DESC
LIMIT 10
