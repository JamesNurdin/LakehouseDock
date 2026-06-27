WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        count(*) AS post_count,
        sum(score) AS total_post_score,
        sum(viewcount) AS total_viewcount,
        sum(answercount) AS total_answer_count,
        sum(commentcount) AS total_comment_count,
        sum(favoritecount) AS total_favorite_count
    FROM posts
    GROUP BY owneruserid
),
user_edits AS (
    SELECT
        lasteditoruserid AS userid,
        count(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT
        userid,
        count(*) AS comment_count,
        sum(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid,
        count(*) AS votes_cast,
        sum(CASE WHEN bountyamount IS NOT NULL THEN bountyamount ELSE 0 END) AS total_bounty_given
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        count(*) AS votes_received,
        sum(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS total_bounty_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid,
        count(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid,
        count(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_tag_usage AS (
    SELECT
        p.owneruserid AS userid,
        sum(t.count) AS total_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(tu.total_tag_count, 0) AS total_tag_count
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_edits ue ON u.id = ue.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast vc ON u.id = vc.userid
LEFT JOIN user_votes_received vr ON u.id = vr.userid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_posthistory ph ON u.id = ph.userid
LEFT JOIN user_tag_usage tu ON u.id = tu.userid
ORDER BY u.reputation DESC
LIMIT 100
