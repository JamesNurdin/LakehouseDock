WITH org_comments AS (
    SELECT
        o.id AS org_id,
        o.name AS org_name,
        p_parent.id AS region_id,
        p_parent.name AS region_name,
        c.id AS comment_id,
        c.length AS comment_length,
        p.id AS post_id
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    JOIN place p_loc ON p.location_country_id = p_loc.id
    JOIN organisation o ON o.location_place_id = p_loc.id
    JOIN place p_parent ON p_loc.part_of_place_id = p_parent.id
)
SELECT
    org_id,
    org_name,
    region_name,
    count(comment_id) AS total_comments,
    avg(comment_length) AS avg_comment_length,
    count(DISTINCT post_id) AS distinct_posts_commented
FROM org_comments
GROUP BY org_id, org_name, region_name
ORDER BY total_comments DESC
LIMIT 10
