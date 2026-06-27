WITH user_posts AS (
    SELECT u.id AS user_id,
           u.reputation,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           CASE WHEN COUNT(p.id) = 0 THEN 0 ELSE SUM(p.score) / COUNT(p.id) END AS avg_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_views,
           COALESCE(SUM(p.favoritecount), 0) AS total_favorites
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS vote_cast_count,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast_count,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast_count
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS vote_received_count,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_received_count,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_received_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT u.id AS user_id,
           COUNT(t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT u.id AS user_id,
           COUNT(pl.id) AS postlink_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
)
SELECT up.user_id,
       up.reputation,
       up.post_count,
       up.total_post_score,
       up.avg_post_score,
       up.total_views,
       up.total_favorites,
       uc.comment_count,
       uc.total_comment_score,
       uv_cast.vote_cast_count,
       uv_cast.upvote_cast_count,
       uv_cast.downvote_cast_count,
       uv_recv.vote_received_count,
       uv_recv.upvote_received_count,
       uv_recv.downvote_received_count,
       ub.badge_count,
       ue.edit_count,
       ut.tag_count,
       upl.postlink_count,
       (COALESCE(up.post_count, 0) * 10
        + COALESCE(uc.comment_count, 0) * 2
        + COALESCE(uv_cast.vote_cast_count, 0)
        + COALESCE(ub.badge_count, 0) * 5
        + COALESCE(ue.edit_count, 0) * 3
        + COALESCE(ut.tag_count, 0) * 2
        + COALESCE(upl.postlink_count, 0) * 2) AS activity_score
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_recv ON uv_recv.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_edits ue ON ue.user_id = up.user_id
LEFT JOIN user_tags ut ON ut.user_id = up.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = up.user_id
ORDER BY activity_score DESC
LIMIT 100
