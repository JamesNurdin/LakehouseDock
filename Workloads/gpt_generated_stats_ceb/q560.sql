WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_viewcount,
            AVG(score) AS avg_post_score,
            MAX(creationdate) AS latest_post_date
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            SUM(score) AS total_comment_score,
            AVG(score) AS avg_comment_score,
            MAX(creationdate) AS latest_comment_date
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid,
            COUNT(*) AS vote_cast_count,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast,
            SUM(bountyamount) AS total_bounty_given,
            MAX(creationdate) AS latest_vote_date
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count,
            MIN(date) AS earliest_badge_date,
            MAX(date) AS latest_badge_date
        FROM badges
        GROUP BY userid
    ),
    user_tag_counts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creation_date,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(uv.upvote_cast, 0) AS upvote_cast,
    COALESCE(uv.downvote_cast, 0) AS downvote_cast,
    COALESCE(uv.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up      ON up.userid = u.id
LEFT JOIN user_comments uc   ON uc.userid = u.id
LEFT JOIN user_votes uv      ON uv.userid = u.id
LEFT JOIN user_badges ub     ON ub.userid = u.id
LEFT JOIN user_tag_counts ut ON ut.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
