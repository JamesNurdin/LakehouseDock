WITH
    posts_agg AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_posts,
            SUM(score) AS total_post_score,
            AVG(score) AS avg_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    comments_made_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_comments_made,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    comments_received_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(c.id) AS total_comments_received,
            SUM(c.score) AS total_comment_score_received
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    votes_cast_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_votes_cast
        FROM votes
        GROUP BY userid
    ),
    votes_received_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS total_votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badges_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ),
    edits_made_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_edits_made
        FROM posthistory
        GROUP BY userid
    ),
    posthistory_on_user_posts_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(ph.id) AS total_history_on_user_posts
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    links_created_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS total_links_created
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.total_posts, 0) AS total_posts,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(cm.total_comments_made, 0) AS total_comments_made,
    COALESCE(cm.total_comment_score, 0) AS total_comment_score,
    COALESCE(cr.total_comments_received, 0) AS total_comments_received,
    COALESCE(cr.total_comment_score_received, 0) AS total_comment_score_received,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(b.total_badges, 0) AS total_badges,
    COALESCE(e.total_edits_made, 0) AS total_edits_made,
    COALESCE(e2.total_history_on_user_posts, 0) AS total_history_on_user_posts,
    COALESCE(l.total_links_created, 0) AS total_links_created
FROM users u
LEFT JOIN posts_agg p ON u.id = p.user_id
LEFT JOIN comments_made_agg cm ON u.id = cm.user_id
LEFT JOIN comments_received_agg cr ON u.id = cr.user_id
LEFT JOIN votes_cast_agg vc ON u.id = vc.user_id
LEFT JOIN votes_received_agg vr ON u.id = vr.user_id
LEFT JOIN badges_agg b ON u.id = b.user_id
LEFT JOIN edits_made_agg e ON u.id = e.user_id
LEFT JOIN posthistory_on_user_posts_agg e2 ON u.id = e2.user_id
LEFT JOIN links_created_agg l ON u.id = l.user_id
ORDER BY total_post_score DESC
LIMIT 10
