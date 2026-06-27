/*
  User activity summary – aggregates posts, comments, votes, badges, edits, tags and post‑links per user
  and ranks users by total contributions.
*/
WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(p.score) AS post_score_sum
    FROM posts p
    GROUP BY p.owneruserid
),
user_last_edits AS (
    SELECT
        p.lasteditoruserid AS userid,
        COUNT(*) AS last_edit_count
    FROM posts p
    GROUP BY p.lasteditoruserid
),
user_comments AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS votes_cast_count
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(v.id) AS votes_received_count
    FROM posts p
    JOIN votes v
        ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_post_edits AS (
    SELECT
        ph.userid AS userid,
        COUNT(*) AS post_edit_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(t.id) AS tag_count
    FROM posts p
    JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(pl.id) AS postlink_count
    FROM posts p
    JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_metrics AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        COALESCE(up.post_count, 0) AS post_count,
        COALESCE(up.post_score_sum, 0) AS post_score_sum,
        COALESCE(uc.comment_count, 0) AS comment_count,
        COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
        COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
        COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
        COALESCE(ub.badge_count, 0) AS badge_count,
        COALESCE(ue.post_edit_count, 0) AS post_edit_count,
        COALESCE(ul.last_edit_count, 0) AS last_edit_count,
        COALESCE(ut.tag_count, 0) AS tag_count,
        COALESCE(upk.postlink_count, 0) AS postlink_count,
        CASE WHEN COALESCE(up.post_count, 0) > 0 THEN up.post_score_sum / up.post_count END AS avg_post_score,
        CASE WHEN COALESCE(uc.comment_count, 0) > 0 THEN uc.comment_score_sum / uc.comment_count END AS avg_comment_score,
        (COALESCE(up.post_count, 0) +
         COALESCE(uc.comment_count, 0) +
         COALESCE(uvc.votes_cast_count, 0) +
         COALESCE(uvr.votes_received_count, 0) +
         COALESCE(ub.badge_count, 0) +
         COALESCE(ue.post_edit_count, 0) +
         COALESCE(ul.last_edit_count, 0) +
         COALESCE(ut.tag_count, 0) +
         COALESCE(upk.postlink_count, 0)) AS total_contributions
    FROM users u
    LEFT JOIN user_posts up ON up.userid = u.id
    LEFT JOIN user_last_edits ul ON ul.userid = u.id
    LEFT JOIN user_comments uc ON uc.userid = u.id
    LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
    LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
    LEFT JOIN user_badges ub ON ub.userid = u.id
    LEFT JOIN user_post_edits ue ON ue.userid = u.id
    LEFT JOIN user_tags ut ON ut.userid = u.id
    LEFT JOIN user_postlinks upk ON upk.userid = u.id
)
SELECT
    user_id,
    reputation,
    creationdate,
    post_count,
    post_score_sum,
    comment_count,
    comment_score_sum,
    votes_cast_count,
    votes_received_count,
    badge_count,
    post_edit_count,
    last_edit_count,
    tag_count,
    postlink_count,
    avg_post_score,
    avg_comment_score,
    total_contributions,
    ROW_NUMBER() OVER (ORDER BY total_contributions DESC) AS contribution_rank
FROM user_metrics
ORDER BY total_contributions DESC
LIMIT 100
