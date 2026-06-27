WITH comment_likes AS (
    SELECT comment_id,
           COUNT(*) AS like_count
    FROM person_likes_comment
    GROUP BY comment_id
),
org_tag_stats AS (
    SELECT
        o.id                                 AS organization_id,
        o.name                               AS organization_name,
        ct.tag_id,
        COUNT(DISTINCT c.id)                 AS comment_count,
        AVG(c.length)                        AS avg_comment_length,
        SUM(COALESCE(cl.like_count, 0))      AS total_likes
    FROM comment c
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    JOIN person p ON c.creator_person_id = p.id
    JOIN person_work_at_company pwc ON p.id = pwc.person_id
    JOIN organisation o ON pwc.company_id = o.id
    JOIN place pl_org ON o.location_place_id = pl_org.id
    LEFT JOIN comment_likes cl ON c.id = cl.comment_id
    WHERE pl_org.name = 'United States'
    GROUP BY o.id, o.name, ct.tag_id
),
ranked_tags AS (
    SELECT
        organization_id,
        organization_name,
        tag_id,
        comment_count,
        avg_comment_length,
        total_likes,
        ROW_NUMBER() OVER (PARTITION BY organization_id ORDER BY comment_count DESC) AS tag_rank
    FROM org_tag_stats
)
SELECT
    organization_id,
    organization_name,
    tag_id,
    comment_count,
    avg_comment_length,
    total_likes,
    tag_rank
FROM ranked_tags
WHERE tag_rank <= 5
ORDER BY organization_id, tag_rank
