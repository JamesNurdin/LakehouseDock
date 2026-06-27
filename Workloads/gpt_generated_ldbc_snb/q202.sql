WITH created_comments AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS created_comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.creator_person_id
),
liked_comments AS (
    SELECT
        plc.person_id,
        COUNT(*) AS liked_comment_count
    FROM person_likes_comment plc
    GROUP BY plc.person_id
),
comment_tags AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(DISTINCT cht.tag_id) AS distinct_tag_count
    FROM comment c
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    GROUP BY c.creator_person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    pl.name AS city_name,
    COALESCE(cc.created_comment_count, 0) AS created_comment_count,
    COALESCE(cc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(lc.liked_comment_count, 0) AS liked_comment_count,
    COALESCE(ct.distinct_tag_count, 0) AS distinct_tag_count
FROM person p
LEFT JOIN place pl ON p.location_city_id = pl.id
LEFT JOIN created_comments cc ON p.id = cc.person_id
LEFT JOIN liked_comments lc ON p.id = lc.person_id
LEFT JOIN comment_tags ct ON p.id = ct.person_id
ORDER BY created_comment_count DESC
LIMIT 10
