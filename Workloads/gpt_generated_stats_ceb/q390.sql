WITH
    post_stats AS (
        SELECT
            owneruserid,
            COUNT(*) AS post_count,
            COALESCE(SUM(score), 0) AS total_post_score,
            COALESCE(SUM(viewcount), 0) AS total_viewcount,
            COALESCE(SUM(answercount), 0) AS total_answer_count
        FROM posts
        GROUP BY owneruserid
    ),
    comment_stats AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            COALESCE(SUM(score), 0) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    vote_cast_stats AS (
        SELECT
            userid,
            COUNT(*) AS vote_cast_count,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast_count,
            SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast_count
        FROM votes
        GROUP BY userid
    ),
    vote_received_stats AS (
        SELECT
            p.owneruserid,
            COUNT(v.id) AS vote_received_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_received_count,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_received_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badge_stats AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    tag_stats AS (
        SELECT
            p.owneruserid,
            COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlink_stats AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_stats AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_event_count
        FROM posthistory
        GROUP BY userid
    ),
    user_base AS (
        SELECT
            id,
            reputation,
            creationdate,
            views,
            upvotes,
            downvotes
        FROM users
    )
SELECT
    ub.id AS user_id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_score, 0) AS total_post_score,
    COALESCE(ps.total_viewcount, 0) AS total_viewcount,
    COALESCE(ps.total_answer_count, 0) AS total_answer_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_score, 0) AS total_comment_score,
    COALESCE(vcs.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vcs.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(vcs.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(vrs.vote_received_count, 0) AS vote_received_count,
    COALESCE(vrs.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(vrs.downvote_received_count, 0) AS downvote_received_count,
    COALESCE(bs.badge_count, 0) AS badge_count,
    COALESCE(ts.tag_count, 0) AS tag_count,
    COALESCE(pls.postlink_count, 0) AS postlink_count,
    COALESCE(phs.posthistory_event_count, 0) AS posthistory_event_count
FROM user_base ub
LEFT JOIN post_stats ps ON ps.owneruserid = ub.id
LEFT JOIN comment_stats cs ON cs.userid = ub.id
LEFT JOIN vote_cast_stats vcs ON vcs.userid = ub.id
LEFT JOIN vote_received_stats vrs ON vrs.owneruserid = ub.id
LEFT JOIN badge_stats bs ON bs.userid = ub.id
LEFT JOIN tag_stats ts ON ts.owneruserid = ub.id
LEFT JOIN postlink_stats pls ON pls.owneruserid = ub.id
LEFT JOIN posthistory_stats phs ON phs.userid = ub.id
ORDER BY total_post_score DESC
LIMIT 20
