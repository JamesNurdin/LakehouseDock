WITH user_badge_counts AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_post_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        SUM(p.viewcount) AS total_viewcount,
        MIN(p.creationdate) AS first_post_date,
        SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
        SUM(CASE WHEN p.posttypeid = 2 THEN p.score ELSE 0 END) AS total_answer_score
    FROM posts p
    GROUP BY p.owneruserid
),
user_comment_made_counts AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_made_count,
        SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_comment_received_counts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS comment_received_count
    FROM posts p
    JOIN comments c ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_cast_counts AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast_count,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_given
    FROM votes v
    GROUP BY v.userid
),
user_votes_received_counts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received_count
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_edit_counts AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS edit_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_link_counts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS link_count
    FROM posts p
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tag_excerpt_counts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS tag_excerpt_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creation_date,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.answer_count, 0) AS answer_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_answer_score, 0) AS total_answer_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    up.first_post_date,
    COALESCE(ucm.comment_made_count, 0) AS comment_made_count,
    COALESCE(ucr.comment_received_count, 0) AS comment_received_count,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uvr.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(uvr.downvote_received_count, 0) AS downvote_received_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ul.link_count, 0) AS link_count,
    COALESCE(ut.tag_excerpt_count, 0) AS tag_excerpt_count,
    row_number() OVER (ORDER BY u.reputation DESC) AS reputation_rank
FROM users u
LEFT JOIN user_badge_counts ub ON ub.user_id = u.id
LEFT JOIN user_post_stats up ON up.user_id = u.id
LEFT JOIN user_comment_made_counts ucm ON ucm.user_id = u.id
LEFT JOIN user_comment_received_counts ucr ON ucr.user_id = u.id
LEFT JOIN user_votes_cast_counts uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received_counts uvr ON uvr.user_id = u.id
LEFT JOIN user_edit_counts ue ON ue.user_id = u.id
LEFT JOIN user_link_counts ul ON ul.user_id = u.id
LEFT JOIN user_tag_excerpt_counts ut ON ut.user_id = u.id
WHERE ub.badge_count > 0
  AND up.answer_count > 0
ORDER BY u.reputation DESC
LIMIT 10
