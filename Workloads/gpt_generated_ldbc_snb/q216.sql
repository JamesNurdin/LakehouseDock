-- Top 10 forums by member count with post and comment engagement metrics
WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT p.id) AS post_count,
        COALESCE(SUM(plp.like_cnt), 0) AS total_post_likes,
        COALESCE(SUM(pcl.like_cnt), 0) AS total_comment_likes,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT pht.tag_id) AS distinct_post_tag_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN (
        SELECT plp.post_id, COUNT(*) AS like_cnt
        FROM person_likes_post plp
        GROUP BY plp.post_id
    ) plp
        ON plp.post_id = p.id
    LEFT JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    LEFT JOIN (
        SELECT c.parent_post_id AS post_id, COUNT(*) AS like_cnt
        FROM comment c
        JOIN person_likes_comment plc
            ON plc.comment_id = c.id
        GROUP BY c.parent_post_id
    ) pcl
        ON pcl.post_id = p.id
    GROUP BY f.id, f.title
)
SELECT
    forum_id,
    forum_title,
    member_count,
    post_count,
    total_post_likes,
    total_comment_likes,
    avg_post_length,
    distinct_post_tag_count
FROM forum_stats
ORDER BY member_count DESC
LIMIT 10
