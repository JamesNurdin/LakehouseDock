WITH user_base AS (
    SELECT id
    FROM users
),
user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.viewcount), 0) AS avg_post_viewcount
    FROM user_base u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM user_base u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM user_base u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count
    FROM user_base u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_links_created AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS links_created_count
    FROM user_base u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
),
user_links_received AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS links_received_count
    FROM user_base u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.relatedpostid = p.id
    GROUP BY u.id
),
user_tag_excerpts AS (
    SELECT
        u.id AS user_id,
        COUNT(t.id) AS tag_excerpt_count
    FROM user_base u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_given
    FROM user_base u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_received_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_received_count
    FROM user_base u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
)
SELECT
    ub.id AS user_id,
    ub.reputation,
    ub.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_viewcount, 0) AS avg_post_viewcount,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(ubdg.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ulc.links_created_count, 0) AS links_created_count,
    COALESCE(ulr.links_received_count, 0) AS links_received_count,
    COALESCE(ut.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uvr.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(uvr.downvote_received_count, 0) AS downvote_received_count
FROM users ub
LEFT JOIN user_posts up       ON up.user_id = ub.id
LEFT JOIN user_comments uc    ON uc.user_id = ub.id
LEFT JOIN user_badges ubdg    ON ubdg.user_id = ub.id
LEFT JOIN user_edits ue       ON ue.user_id = ub.id
LEFT JOIN user_links_created ulc ON ulc.user_id = ub.id
LEFT JOIN user_links_received ulr ON ulr.user_id = ub.id
LEFT JOIN user_tag_excerpts ut   ON ut.user_id = ub.id
LEFT JOIN user_votes_cast uvc    ON uvc.user_id = ub.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = ub.id
ORDER BY up.total_post_score DESC
LIMIT 10
