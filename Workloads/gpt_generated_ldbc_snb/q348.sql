WITH post_counts AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.creator_person_id
),
post_likes AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(plp.person_id) AS post_like_received
    FROM post p
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.creator_person_id
),
post_tags AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(DISTINCT pt.tag_id) AS post_distinct_tag_count
    FROM post p
    LEFT JOIN post_has_tag_tag pt ON pt.post_id = p.id
    GROUP BY p.creator_person_id
),
comment_counts AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.creator_person_id
),
comment_likes AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(plc.person_id) AS comment_like_received
    FROM comment c
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY c.creator_person_id
),
comment_tags AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(DISTINCT ct.tag_id) AS comment_distinct_tag_count
    FROM comment c
    LEFT JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    GROUP BY c.creator_person_id
),
person_info AS (
    SELECT
        per.id,
        per.first_name,
        per.last_name,
        per.gender,
        per.birthday,
        per.email,
        per.location_city_id
    FROM person per
)
SELECT
    pi.id AS person_id,
    pi.first_name,
    pi.last_name,
    COALESCE(pc.post_count, 0) AS post_count,
    COALESCE(pl.post_like_received, 0) AS post_like_received,
    COALESCE(pt.post_distinct_tag_count, 0) AS post_distinct_tag_count,
    COALESCE(pc.avg_post_length, 0) AS avg_post_length,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(cl.comment_like_received, 0) AS comment_like_received,
    COALESCE(ct.comment_distinct_tag_count, 0) AS comment_distinct_tag_count,
    COALESCE(cc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pc.post_count, 0) + COALESCE(cc.comment_count, 0) AS total_content_count,
    COALESCE(pl.post_like_received, 0) + COALESCE(cl.comment_like_received, 0) AS total_likes_received,
    COALESCE(pt.post_distinct_tag_count, 0) + COALESCE(ct.comment_distinct_tag_count, 0) AS total_distinct_tags_used
FROM person_info pi
LEFT JOIN post_counts pc ON pc.person_id = pi.id
LEFT JOIN post_likes pl ON pl.person_id = pi.id
LEFT JOIN post_tags pt ON pt.person_id = pi.id
LEFT JOIN comment_counts cc ON cc.person_id = pi.id
LEFT JOIN comment_likes cl ON cl.person_id = pi.id
LEFT JOIN comment_tags ct ON ct.person_id = pi.id
ORDER BY total_likes_received DESC
LIMIT 100
