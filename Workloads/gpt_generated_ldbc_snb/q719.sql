WITH post_base AS (
    SELECT
        po.id AS post_id,
        po.creator_person_id,
        po.location_country_id
    FROM post po
),
likes_agg AS (
    SELECT
        plp.post_id,
        COUNT(DISTINCT plp.person_id) AS like_count
    FROM person_likes_post plp
    GROUP BY plp.post_id
),
comments_agg AS (
    SELECT
        c.parent_post_id AS post_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.parent_post_id
),
post_metrics AS (
    SELECT
        pb.post_id,
        pb.creator_person_id,
        pb.location_country_id,
        COALESCE(la.like_count, 0) AS like_count,
        COALESCE(ca.comment_count, 0) AS comment_count,
        ca.avg_comment_length
    FROM post_base pb
    LEFT JOIN likes_agg la ON la.post_id = pb.post_id
    LEFT JOIN comments_agg ca ON ca.post_id = pb.post_id
)
SELECT
    org.id AS company_id,
    org.name AS company_name,
    plc.id AS post_country_id,
    plc.name AS post_country_name,
    COUNT(DISTINCT pm.post_id) AS post_count,
    SUM(pm.like_count) AS total_likes,
    AVG(pm.comment_count) AS avg_comments_per_post,
    AVG(pm.avg_comment_length) AS avg_comment_length
FROM post_metrics pm
JOIN person p
    ON pm.creator_person_id = p.id
JOIN person_work_at_company pwac
    ON pwac.person_id = p.id
JOIN organisation org
    ON pwac.company_id = org.id
    AND org.type = 'company'
JOIN place plc
    ON pm.location_country_id = plc.id
GROUP BY org.id, org.name, plc.id, plc.name
ORDER BY total_likes DESC
LIMIT 20
