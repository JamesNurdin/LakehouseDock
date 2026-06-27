WITH
    user_basic AS (
        SELECT
            id AS user_id,
            reputation,
            creationdate,
            views,
            upvotes,
            downvotes
        FROM users
    ),
    badge_counts AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    post_counts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            AVG(score) AS avg_post_score,
            SUM(viewcount) AS total_viewcount,
            SUM(favoritecount) AS total_favoritecount,
            SUM(answercount) AS total_answercount,
            SUM(commentcount) AS total_commentcount
        FROM posts
        GROUP BY owneruserid
    ),
    comment_counts AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    vote_cast_counts AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY userid
    ),
    votes_received_counts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS votes_received_count
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    tag_counts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(t.id) AS tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_counts AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    postlink_counts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS postlink_count
        FROM posts p
        JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.user_id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(pc.post_count, 0) AS post_count,
    COALESCE(pc.total_post_score, 0) AS total_post_score,
    pc.avg_post_score,
    COALESCE(pc.total_viewcount, 0) AS total_viewcount,
    COALESCE(pc.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(pc.total_answercount, 0) AS total_answercount,
    COALESCE(pc.total_commentcount, 0) AS total_commentcount,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(vcc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vrc.votes_received_count, 0) AS votes_received_count,
    COALESCE(tc.tag_count, 0) AS tag_count,
    COALESCE(phc.posthistory_count, 0) AS posthistory_count,
    COALESCE(plc.postlink_count, 0) AS postlink_count
FROM user_basic ub
LEFT JOIN badge_counts bc ON bc.user_id = ub.user_id
LEFT JOIN post_counts pc ON pc.user_id = ub.user_id
LEFT JOIN comment_counts cc ON cc.user_id = ub.user_id
LEFT JOIN vote_cast_counts vcc ON vcc.user_id = ub.user_id
LEFT JOIN votes_received_counts vrc ON vrc.user_id = ub.user_id
LEFT JOIN tag_counts tc ON tc.user_id = ub.user_id
LEFT JOIN posthistory_counts phc ON phc.user_id = ub.user_id
LEFT JOIN postlink_counts plc ON plc.user_id = ub.user_id
ORDER BY ub.reputation DESC
LIMIT 100
