WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(DISTINCT c.id) AS comment_count,
        COALESCE(SUM(plp.like_cnt), 0) AS post_like_count,
        COALESCE(SUM(plc.like_cnt), 0) AS comment_like_count
    FROM forum f
    JOIN person mod ON f.moderator_person_id = mod.id
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    LEFT JOIN (
        SELECT post_id, COUNT(*) AS like_cnt
        FROM person_likes_post
        GROUP BY post_id
    ) plp ON plp.post_id = p.id
    LEFT JOIN (
        SELECT comment_id, COUNT(*) AS like_cnt
        FROM person_likes_comment
        GROUP BY comment_id
    ) plc ON plc.comment_id = c.id
    GROUP BY f.id, f.title, mod.first_name, mod.last_name
),

top_tags_per_forum AS (
    SELECT
        p.container_forum_id AS forum_id,
        tg.id AS tag_id,
        tg.name AS tag_name,
        COUNT(*) AS post_cnt,
        ROW_NUMBER() OVER (PARTITION BY p.container_forum_id ORDER BY COUNT(*) DESC) AS rn
    FROM post p
    JOIN post_has_tag_tag pht ON p.id = pht.post_id
    JOIN tag tg ON pht.tag_id = tg.id
    GROUP BY p.container_forum_id, tg.id, tg.name
)
SELECT
    fs.forum_id,
    fs.forum_title,
    fs.moderator_first_name,
    fs.moderator_last_name,
    fs.post_count,
    fs.comment_count,
    fs.post_like_count,
    fs.comment_like_count,
    (fs.post_count + fs.comment_count + fs.post_like_count + fs.comment_like_count) AS total_activity,
    tt.tag_name AS top_tag_name,
    tt.post_cnt AS top_tag_post_count
FROM forum_stats fs
LEFT JOIN top_tags_per_forum tt
    ON tt.forum_id = fs.forum_id AND tt.rn = 1
ORDER BY total_activity DESC
LIMIT 10
