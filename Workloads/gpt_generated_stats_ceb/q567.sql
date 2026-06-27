WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_score,
            AVG(p.score) AS avg_score,
            COUNT(DISTINCT CASE WHEN p.posttypeid = 1 THEN p.id END) AS question_count,
            COUNT(DISTINCT CASE WHEN p.posttypeid = 2 THEN p.id END) AS answer_count
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comment_count
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS vote_cast_count
        FROM votes v
        GROUP BY v.userid
    ),
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_edits AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS edit_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_linked_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT pl.id) AS linked_post_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_post_score,
    COALESCE(up.avg_score, 0) AS avg_post_score,
    COALESCE(up.question_count, 0) AS question_count,
    COALESCE(up.answer_count, 0) AS answer_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ul.linked_post_count, 0) AS linked_post_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_linked_posts ul ON ul.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY post_count DESC
LIMIT 100
