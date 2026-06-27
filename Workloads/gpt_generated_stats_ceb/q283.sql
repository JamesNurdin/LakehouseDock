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
    posts_by_user AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            COALESCE(SUM(score), 0) AS total_post_score,
            COALESCE(SUM(viewcount), 0) AS total_view_count,
            COALESCE(SUM(answercount), 0) AS total_answer_count,
            COALESCE(SUM(commentcount), 0) AS total_comment_count,
            COALESCE(SUM(favoritecount), 0) AS total_favorite_count
        FROM posts
        GROUP BY owneruserid
    ),
    comments_received_by_user AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS comment_received_count
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    votes_received_by_user AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS vote_received_count,
            COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    votes_cast_by_user AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS vote_cast_count,
            COALESCE(SUM(bountyamount), 0) AS total_bounty_cast
        FROM votes
        GROUP BY userid
    ),
    badges_by_user AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    posthistory_by_user AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS edit_count
        FROM posthistory
        GROUP BY userid
    ),
    last_edits_by_user AS (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(DISTINCT id) AS distinct_posts_last_edited
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    tags_by_user AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.user_id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(pb.post_count, 0) AS post_count,
    COALESCE(pb.total_post_score, 0) AS total_post_score,
    COALESCE(pb.total_view_count, 0) AS total_view_count,
    COALESCE(pb.total_answer_count, 0) AS total_answer_count,
    COALESCE(pb.total_comment_count, 0) AS total_comment_count,
    COALESCE(pb.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(cr.comment_received_count, 0) AS comment_received_count,
    COALESCE(vr.vote_received_count, 0) AS vote_received_count,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(vc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vc.total_bounty_cast, 0) AS total_bounty_cast,
    COALESCE(bb.badge_count, 0) AS badge_count,
    COALESCE(ph.edit_count, 0) AS edit_count,
    COALESCE(le.distinct_posts_last_edited, 0) AS distinct_posts_last_edited,
    COALESCE(tb.tag_count, 0) AS tag_count
FROM user_base ub
LEFT JOIN posts_by_user pb ON ub.user_id = pb.user_id
LEFT JOIN comments_received_by_user cr ON ub.user_id = cr.user_id
LEFT JOIN votes_received_by_user vr ON ub.user_id = vr.user_id
LEFT JOIN votes_cast_by_user vc ON ub.user_id = vc.user_id
LEFT JOIN badges_by_user bb ON ub.user_id = bb.user_id
LEFT JOIN posthistory_by_user ph ON ub.user_id = ph.user_id
LEFT JOIN last_edits_by_user le ON ub.user_id = le.user_id
LEFT JOIN tags_by_user tb ON ub.user_id = tb.user_id
ORDER BY ub.reputation DESC
LIMIT 100
