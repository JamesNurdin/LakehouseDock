WITH
    user_base AS (
        SELECT
            id AS user_id,
            reputation,
            creationdate,
            views,
            upvotes,
            downvotes
        FROM users
    ),
    post_stats AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_viewcount,
            AVG(answercount) AS avg_answer_count,
            AVG(commentcount) AS avg_comment_count,
            SUM(favoritecount) AS total_favorite_count
        FROM posts
        GROUP BY owneruserid
    ),
    comment_stats AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    vote_cast_stats AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS vote_cast_count,
            SUM(COALESCE(bountyamount, 0)) AS total_bounty_given
        FROM votes
        GROUP BY userid
    ),
    vote_received_stats AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received,
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badge_stats AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    posthistory_stats AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    tag_stats AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlink_stats AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.user_id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_score, 0) AS total_post_score,
    COALESCE(ps.total_viewcount, 0) AS total_viewcount,
    COALESCE(ps.avg_answer_count, 0) AS avg_answer_count,
    COALESCE(ps.avg_comment_count, 0) AS avg_comment_count,
    COALESCE(ps.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_score, 0) AS total_comment_score,
    COALESCE(vcs.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vcs.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(vrs.votes_received, 0) AS votes_received,
    COALESCE(vrs.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(bs.badge_count, 0) AS badge_count,
    COALESCE(phs.posthistory_count, 0) AS posthistory_count,
    COALESCE(ts.tag_count, 0) AS tag_count,
    COALESCE(pls.postlink_count, 0) AS postlink_count,
    (COALESCE(ps.post_count, 0) * 5
     + COALESCE(cs.comment_count, 0) * 2
     + COALESCE(vcs.vote_cast_count, 0)
     + COALESCE(vrs.votes_received, 0) * 2
     + COALESCE(bs.badge_count, 0) * 3
     + COALESCE(ts.tag_count, 0) * 1
     + COALESCE(pls.postlink_count, 0) * 1) AS activity_score
FROM user_base ub
LEFT JOIN post_stats ps ON ub.user_id = ps.user_id
LEFT JOIN comment_stats cs ON ub.user_id = cs.user_id
LEFT JOIN vote_cast_stats vcs ON ub.user_id = vcs.user_id
LEFT JOIN vote_received_stats vrs ON ub.user_id = vrs.user_id
LEFT JOIN badge_stats bs ON ub.user_id = bs.user_id
LEFT JOIN posthistory_stats phs ON ub.user_id = phs.user_id
LEFT JOIN tag_stats ts ON ub.user_id = ts.user_id
LEFT JOIN postlink_stats pls ON ub.user_id = pls.user_id
ORDER BY activity_score DESC
LIMIT 20
