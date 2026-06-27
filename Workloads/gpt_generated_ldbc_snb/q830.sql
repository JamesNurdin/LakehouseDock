WITH
    post_likes AS (
        SELECT
            pl.post_id,
            COUNT(pl.person_id) AS like_cnt
        FROM person_likes_post pl
        GROUP BY pl.post_id
    ),
    comment_likes AS (
        SELECT
            cl.comment_id,
            COUNT(cl.person_id) AS like_cnt
        FROM person_likes_comment cl
        GROUP BY cl.comment_id
    ),
    forum_post_stats AS (
        SELECT
            f.id AS forum_id,
            f.title AS forum_title,
            COUNT(DISTINCT p.id) AS total_posts,
            COALESCE(SUM(pl.like_cnt), 0) AS total_post_likes
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        LEFT JOIN post_likes pl ON pl.post_id = p.id
        GROUP BY f.id, f.title
    ),
    forum_comment_stats AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT c.id) AS total_comments,
            COALESCE(SUM(cl.like_cnt), 0) AS total_comment_likes
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        LEFT JOIN comment c ON c.parent_post_id = p.id
        LEFT JOIN comment_likes cl ON cl.comment_id = c.id
        GROUP BY f.id
    ),
    forum_participant_stats AS (
        SELECT
            forum_id,
            COUNT(DISTINCT participant_id) AS distinct_participants
        FROM (
            SELECT
                f.id AS forum_id,
                p.creator_person_id AS participant_id
            FROM forum f
            JOIN post p ON p.container_forum_id = f.id
            UNION
            SELECT
                f.id AS forum_id,
                c.creator_person_id AS participant_id
            FROM forum f
            JOIN post p ON p.container_forum_id = f.id
            JOIN comment c ON c.parent_post_id = p.id
        ) participants
        GROUP BY forum_id
    )
SELECT
    fps.forum_id,
    fps.forum_title,
    fps.total_posts,
    fcs.total_comments,
    fps.total_post_likes,
    fcs.total_comment_likes,
    fpsp.distinct_participants
FROM forum_post_stats fps
LEFT JOIN forum_comment_stats fcs ON fcs.forum_id = fps.forum_id
LEFT JOIN forum_participant_stats fpsp ON fpsp.forum_id = fps.forum_id
ORDER BY fps.total_posts DESC
LIMIT 10
