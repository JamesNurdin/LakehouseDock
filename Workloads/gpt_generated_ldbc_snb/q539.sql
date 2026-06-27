WITH post_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
member_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id
),
tag_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum f
    LEFT JOIN forum_has_tag_tag ft ON ft.forum_id = f.id
    GROUP BY f.id
),
comment_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
moderator_info AS (
    SELECT
        f.id AS forum_id,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person p ON p.id = f.moderator_person_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(ms.member_count, 0) AS member_count,
    COALESCE(ts.tag_count, 0) AS tag_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    mi.moderator_first_name,
    mi.moderator_last_name
FROM forum f
LEFT JOIN post_stats ps ON ps.forum_id = f.id
LEFT JOIN member_stats ms ON ms.forum_id = f.id
LEFT JOIN tag_stats ts ON ts.forum_id = f.id
LEFT JOIN comment_stats cs ON cs.forum_id = f.id
LEFT JOIN moderator_info mi ON mi.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10
