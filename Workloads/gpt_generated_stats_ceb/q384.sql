WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
        SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
        COALESCE(SUM(p.score), 0) AS total_score,
        COALESCE(SUM(CASE WHEN p.posttypeid = 1 THEN p.viewcount ELSE 0 END), 0) AS total_question_views,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count,
        COALESCE(SUM(p.commentcount), 0) AS total_post_comments
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score_sum
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast_count,
        COALESCE(SUM(v.bountyamount), 0) AS bounty_given
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received_count,
        COALESCE(SUM(v.votetypeid), 0) AS votes_received_type_sum
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS owned_tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.question_count, 0) AS question_count,
    COALESCE(up.answer_count, 0) AS answer_count,
    COALESCE(up.total_score, 0) AS total_post_score,
    COALESCE(up.total_question_views, 0) AS total_question_views,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(up.total_post_comments, 0) AS total_post_comments,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.bounty_given, 0) AS bounty_given,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uvr.votes_received_type_sum, 0) AS votes_received_type_sum,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.owned_tag_excerpt_count, 0) AS owned_tag_excerpt_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
