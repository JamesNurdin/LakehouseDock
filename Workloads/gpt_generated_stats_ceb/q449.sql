WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS post_score_sum,
        SUM(p.viewcount) AS post_view_sum,
        SUM(p.answercount) AS post_answer_sum,
        SUM(p.commentcount) AS post_comment_sum,
        SUM(p.favoritecount) AS post_favorite_sum
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
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast,
        SUM(v.bountyamount) AS bounty_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received,
        SUM(v.bountyamount) AS bounty_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_edits AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS edit_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_edits_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS edit_received_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        SUM(t.count) AS tag_usage_sum
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_links_as_post AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS link_as_post_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_links_as_related AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS link_as_related_count
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(up.post_answer_sum, 0) AS post_answer_sum,
    COALESCE(up.post_comment_sum, 0) AS post_comment_sum,
    COALESCE(up.post_favorite_sum, 0) AS post_favorite_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.upvote_cast, 0) AS upvote_cast,
    COALESCE(uvc.downvote_cast, 0) AS downvote_cast,
    COALESCE(uvc.bounty_cast, 0) AS bounty_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvote_received, 0) AS upvote_received,
    COALESCE(uvr.downvote_received, 0) AS downvote_received,
    COALESCE(uvr.bounty_received, 0) AS bounty_received,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uer.edit_received_count, 0) AS edit_received_count,
    COALESCE(ut.tag_usage_sum, 0) AS tag_usage_sum,
    COALESCE(ulp.link_as_post_count, 0) AS link_as_post_count,
    COALESCE(ulr.link_as_related_count, 0) AS link_as_related_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_edits_received uer ON uer.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_links_as_post ulp ON ulp.user_id = u.id
LEFT JOIN user_links_as_related ulr ON ulr.user_id = u.id
ORDER BY post_score_sum DESC
LIMIT 100
