WITH
    user_base AS (
        SELECT id,
               reputation,
               creationdate,
               views,
               upvotes,
               downvotes
        FROM users
    ),
    posts_owned AS (
        SELECT owneruserid AS user_id,
               COUNT(*) AS total_posts_owned,
               COALESCE(SUM(score), 0) AS total_post_score,
               COALESCE(SUM(viewcount), 0) AS total_post_viewcount
        FROM posts
        GROUP BY owneruserid
    ),
    comments_made AS (
        SELECT userid AS user_id,
               COUNT(*) AS total_comments_made,
               COALESCE(SUM(score), 0) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    votes_cast AS (
        SELECT userid AS user_id,
               COUNT(*) AS total_votes_cast
        FROM votes
        GROUP BY userid
    ),
    votes_received AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS total_votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badges_earned AS (
        SELECT userid AS user_id,
               COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ),
    posthistory_actions AS (
        SELECT userid AS user_id,
               COUNT(*) AS total_posthistory_entries
        FROM posthistory
        GROUP BY userid
    ),
    tags_excerpts AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS total_tags_excerpts
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(po.total_posts_owned, 0)          AS total_posts_owned,
    COALESCE(po.total_post_score, 0)           AS total_post_score,
    COALESCE(po.total_post_viewcount, 0)      AS total_post_viewcount,
    COALESCE(cm.total_comments_made, 0)       AS total_comments_made,
    COALESCE(cm.total_comment_score, 0)       AS total_comment_score,
    COALESCE(vc.total_votes_cast, 0)          AS total_votes_cast,
    COALESCE(vr.total_votes_received, 0)      AS total_votes_received,
    COALESCE(be.total_badges, 0)              AS total_badges,
    COALESCE(ph.total_posthistory_entries, 0) AS total_posthistory_entries,
    COALESCE(te.total_tags_excerpts, 0)        AS total_tags_excerpts
FROM user_base ub
LEFT JOIN posts_owned po          ON po.user_id = ub.id
LEFT JOIN comments_made cm        ON cm.user_id = ub.id
LEFT JOIN votes_cast vc           ON vc.user_id = ub.id
LEFT JOIN votes_received vr       ON vr.user_id = ub.id
LEFT JOIN badges_earned be        ON be.user_id = ub.id
LEFT JOIN posthistory_actions ph  ON ph.user_id = ub.id
LEFT JOIN tags_excerpts te        ON te.user_id = ub.id
ORDER BY total_posts_owned DESC, total_votes_received DESC
LIMIT 10
