WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        AVG(score) AS post_score_avg,
        SUM(viewcount) AS post_view_sum,
        SUM(answercount) AS answer_sum,
        SUM(commentcount) AS comment_sum,
        SUM(favoritecount) AS favorite_sum
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid,
        COUNT(*) AS vote_count,
        SUM(COALESCE(bountyamount, 0)) AS bounty_sum
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(pl.id) AS postlink_count
    FROM posts p
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(t.id) AS tag_count
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creation_date,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(up.answer_sum, 0) AS answer_sum,
    COALESCE(up.comment_sum, 0) AS comment_sum,
    COALESCE(up.favorite_sum, 0) AS favorite_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.bounty_sum, 0) AS bounty_sum,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(upL.postlink_count, 0) AS postlink_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up      ON up.userid = u.id
LEFT JOIN user_comments uc   ON uc.userid = u.id
LEFT JOIN user_votes uv      ON uv.userid = u.id
LEFT JOIN user_badges ub     ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_postlinks upL ON upL.userid = u.id
LEFT JOIN user_tags ut       ON ut.userid = u.id
ORDER BY post_count DESC
LIMIT 100
