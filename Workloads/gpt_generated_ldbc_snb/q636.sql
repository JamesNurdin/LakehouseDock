WITH
    post_likes AS (
        SELECT
            post_id,
            COUNT(*) AS like_count
        FROM person_likes_post
        GROUP BY post_id
    ),
    comment_likes AS (
        SELECT
            comment_id,
            COUNT(*) AS like_count
        FROM person_likes_comment
        GROUP BY comment_id
    ),
    post_metrics AS (
        SELECT
            f.id AS forum_id,
            f.title AS forum_title,
            COUNT(p.id) AS post_count,
            SUM(p.length) AS total_post_length,
            AVG(p.length) AS avg_post_length,
            COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators,
            COALESCE(SUM(pl.like_count), 0) AS post_like_count
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        LEFT JOIN post_likes pl ON pl.post_id = p.id
        GROUP BY f.id, f.title
    ),
    comment_metrics AS (
        SELECT
            f.id AS forum_id,
            COUNT(c.id) AS comment_count,
            SUM(c.length) AS total_comment_length,
            AVG(c.length) AS avg_comment_length,
            COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creators,
            COALESCE(SUM(cl.like_count), 0) AS comment_like_count
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        LEFT JOIN comment c ON c.parent_post_id = p.id
        LEFT JOIN comment_likes cl ON cl.comment_id = c.id
        GROUP BY f.id
    ),
    participants AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT u.person_id) AS participant_count
        FROM forum f
        LEFT JOIN (
            SELECT p.creator_person_id AS person_id, p.container_forum_id AS forum_id
            FROM post p
            UNION
            SELECT c.creator_person_id AS person_id, p.container_forum_id AS forum_id
            FROM comment c
            JOIN post p ON c.parent_post_id = p.id
        ) u ON u.forum_id = f.id
        GROUP BY f.id
    )
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.total_post_length, 0) AS total_post_length,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(pm.post_like_count, 0) AS post_like_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.total_comment_length, 0) AS total_comment_length,
    COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cm.comment_like_count, 0) AS comment_like_count,
    COALESCE(p.participant_count, 0) AS participant_count,
    CONCAT(mod.first_name, ' ', mod.last_name) AS moderator_name
FROM forum f
LEFT JOIN post_metrics pm ON pm.forum_id = f.id
LEFT JOIN comment_metrics cm ON cm.forum_id = f.id
LEFT JOIN participants p ON p.forum_id = f.id
LEFT JOIN person mod ON mod.id = f.moderator_person_id
ORDER BY post_count DESC
LIMIT 20
