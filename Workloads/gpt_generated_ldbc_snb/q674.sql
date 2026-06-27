WITH members AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
moderators AS (
    SELECT
        f.id AS forum_id,
        p.first_name,
        p.last_name
    FROM forum f
    LEFT JOIN person p ON f.moderator_person_id = p.id
),
posts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comments AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_like_count
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_like_count
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_tags AS (
    SELECT
        fm.forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT fm.person_id) AS interested_member_count
    FROM forum_has_member_person fm
    JOIN person p ON p.id = fm.person_id
    JOIN person_has_interest_tag pit ON pit.person_id = p.id
    JOIN tag t ON t.id = pit.tag_id
    GROUP BY fm.forum_id, t.id, t.name
),
top_forum_tag AS (
    SELECT
        forum_id,
        tag_name,
        interested_member_count,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY interested_member_count DESC) AS rn
    FROM forum_tags
)
SELECT
    f.id AS forum_id,
    f.title,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pl.post_like_count, 0) AS post_like_count,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count,
    COALESCE(tft.tag_name, 'N/A') AS top_tag,
    COALESCE(tft.interested_member_count, 0) AS top_tag_member_count,
    CONCAT(mo.first_name, ' ', mo.last_name) AS moderator_name
FROM forum f
LEFT JOIN members m ON m.forum_id = f.id
LEFT JOIN moderators mo ON mo.forum_id = f.id
LEFT JOIN posts p ON p.forum_id = f.id
LEFT JOIN comments c ON c.forum_id = f.id
LEFT JOIN post_likes pl ON pl.forum_id = f.id
LEFT JOIN comment_likes cl ON cl.forum_id = f.id
LEFT JOIN top_forum_tag tft ON tft.forum_id = f.id AND tft.rn = 1
ORDER BY member_count DESC
LIMIT 50
