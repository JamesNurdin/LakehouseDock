WITH user_info AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM users u
),
user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS post_score_sum,
        AVG(p.score) AS post_score_avg,
        SUM(p.viewcount) AS post_view_sum,
        SUM(p.answercount) AS answer_count_sum,
        SUM(p.commentcount) AS comment_count_sum,
        SUM(p.favoritecount) AS favorite_count_sum
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_given,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_given,
        SUM(v.bountyamount) AS bounty_given
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
        p.lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_history AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS history_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_links AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    ui.user_id,
    ui.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uv.vote_count, 0) AS vote_given_count,
    COALESCE(uv.upvote_given, 0) AS upvote_given,
    COALESCE(uv.downvote_given, 0) AS downvote_given,
    COALESCE(uv.bounty_given, 0) AS bounty_given,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uh.history_count, 0) AS history_count,
    COALESCE(ul.postlink_count, 0) AS postlink_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM user_info ui
LEFT JOIN user_posts up ON up.user_id = ui.user_id
LEFT JOIN user_comments uc ON uc.user_id = ui.user_id
LEFT JOIN user_votes uv ON uv.user_id = ui.user_id
LEFT JOIN user_badges ub ON ub.user_id = ui.user_id
LEFT JOIN user_edits ue ON ue.user_id = ui.user_id
LEFT JOIN user_history uh ON uh.user_id = ui.user_id
LEFT JOIN user_links ul ON ul.user_id = ui.user_id
LEFT JOIN user_tags ut ON ut.user_id = ui.user_id
ORDER BY ui.reputation DESC
LIMIT 100
