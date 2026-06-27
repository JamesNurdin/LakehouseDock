WITH
    member_counts AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum_has_member_person fm
        JOIN forum f ON fm.forum_id = f.id
        GROUP BY f.id
    ),
    post_stats AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT p.id) AS post_count,
               AVG(p.length) AS avg_post_length
        FROM post p
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    comment_stats AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT c.id) AS comment_count,
               AVG(c.length) AS avg_comment_length
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    post_like_counts AS (
        SELECT f.id AS forum_id,
               COUNT(*) AS post_like_count
        FROM person_likes_post plp
        JOIN post p ON plp.post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    comment_like_counts AS (
        SELECT f.id AS forum_id,
               COUNT(*) AS comment_like_count
        FROM person_likes_comment plc
        JOIN comment c ON plc.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    forum_tag_counts AS (
        SELECT f.id AS forum_id,
               pht.tag_id,
               COUNT(*) AS tag_usage_count
        FROM post_has_tag_tag pht
        JOIN post p ON pht.post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
        GROUP BY f.id, pht.tag_id
    ),
    top_forum_tags AS (
        SELECT forum_id,
               tag_id,
               tag_usage_count,
               ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage_count DESC) AS rn
        FROM forum_tag_counts
    )
SELECT f.id AS forum_id,
       f.title,
       mc.member_count,
       ps.post_count,
       ps.avg_post_length,
       cs.comment_count,
       cs.avg_comment_length,
       plc.post_like_count,
       clc.comment_like_count,
       tft.tag_id,
       tft.tag_usage_count
FROM forum f
LEFT JOIN member_counts mc ON f.id = mc.forum_id
LEFT JOIN post_stats ps ON f.id = ps.forum_id
LEFT JOIN comment_stats cs ON f.id = cs.forum_id
LEFT JOIN post_like_counts plc ON f.id = plc.forum_id
LEFT JOIN comment_like_counts clc ON f.id = clc.forum_id
LEFT JOIN (
    SELECT forum_id, tag_id, tag_usage_count
    FROM top_forum_tags
    WHERE rn <= 3
) tft ON f.id = tft.forum_id
ORDER BY f.id, tft.tag_usage_count DESC
