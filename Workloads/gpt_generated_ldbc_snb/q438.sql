WITH post_tag_stats AS (
    SELECT
        t.id,
        t.name,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(pl.person_id) AS post_like_count,
        COUNT(DISTINCT p.creator_person_id) AS post_creator_count
    FROM post_has_tag_tag ptt
    JOIN post p ON ptt.post_id = p.id
    JOIN tag t ON ptt.tag_id = t.id
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY t.id, t.name
),
comment_tag_stats AS (
    SELECT
        t.id,
        t.name,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(cl.person_id) AS comment_like_count,
        COUNT(DISTINCT c.creator_person_id) AS comment_creator_count
    FROM comment_has_tag_tag ctt
    JOIN comment c ON ctt.comment_id = c.id
    JOIN tag t ON ctt.tag_id = t.id
    LEFT JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY t.id, t.name
),
interest_stats AS (
    SELECT
        t.id,
        t.name,
        COUNT(DISTINCT p.id) AS interest_person_count
    FROM person_has_interest_tag pit
    JOIN tag t ON pit.tag_id = t.id
    JOIN person p ON pit.person_id = p.id
    GROUP BY t.id, t.name
)
SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    COALESCE(pt.post_count, 0) AS post_count,
    COALESCE(pt.post_like_count, 0) AS post_like_count,
    COALESCE(pt.post_creator_count, 0) AS post_creator_count,
    COALESCE(ct.comment_count, 0) AS comment_count,
    COALESCE(ct.comment_like_count, 0) AS comment_like_count,
    COALESCE(ct.comment_creator_count, 0) AS comment_creator_count,
    COALESCE(i.interest_person_count, 0) AS interest_person_count,
    (COALESCE(pt.post_count, 0) + COALESCE(ct.comment_count, 0)) AS total_content,
    (COALESCE(pt.post_like_count, 0) + COALESCE(ct.comment_like_count, 0)) AS total_likes,
    (COALESCE(pt.post_creator_count, 0) + COALESCE(ct.comment_creator_count, 0) + COALESCE(i.interest_person_count, 0)) AS engagement_score
FROM tag t
LEFT JOIN post_tag_stats pt ON pt.id = t.id
LEFT JOIN comment_tag_stats ct ON ct.id = t.id
LEFT JOIN interest_stats i ON i.id = t.id
ORDER BY engagement_score DESC
LIMIT 10
