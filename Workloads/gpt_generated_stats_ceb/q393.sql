WITH user_posts AS (
    SELECT
        owneruserid,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        AVG(score) AS post_score_avg,
        COUNT(DISTINCT posttypeid) AS distinct_posttype_count
    FROM posts
    GROUP BY owneruserid
),
user_edits AS (
    SELECT
        lasteditoruserid,
        COUNT(*) AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast,
        SUM(COALESCE(bountyamount, 0)) AS bounty_given_sum
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS votes_received,
        SUM(COALESCE(v.bountyamount, 0)) AS bounty_received_sum
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
)

SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS total_posts_owned,
    COALESCE(up.post_score_sum, 0) AS total_post_score,
    COALESCE(up.post_score_avg, 0) AS avg_post_score,
    COALESCE(up.distinct_posttype_count, 0) AS distinct_post_type_count,
    COALESCE(ue.edit_count, 0) AS total_posts_edited,
    COALESCE(uc.comment_count, 0) AS total_comments_made,
    COALESCE(uc.comment_score_sum, 0) AS total_comment_score,
    COALESCE(uvc.votes_cast, 0) AS total_votes_cast,
    COALESCE(uvc.bounty_given_sum, 0) AS total_bounty_given,
    COALESCE(uvr.votes_received, 0) AS total_votes_received_on_owned_posts,
    COALESCE(uvr.bounty_received_sum, 0) AS total_bounty_received,
    COALESCE(ub.badge_count, 0) AS total_badges_earned
FROM users u
LEFT JOIN user_posts up ON u.id = up.owneruserid
LEFT JOIN user_edits ue ON u.id = ue.lasteditoruserid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast uvc ON u.id = uvc.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.owneruserid
LEFT JOIN user_badges ub ON u.id = ub.userid
ORDER BY total_posts_owned DESC
LIMIT 100
