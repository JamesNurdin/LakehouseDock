WITH
    posts_agg AS (
        SELECT
            owneruserid,
            COUNT(*) AS total_posts,
            SUM(score) AS total_post_score,
            AVG(score) AS avg_post_score,
            SUM(viewcount) AS total_views
        FROM posts
        GROUP BY owneruserid
    ),
    comments_agg AS (
        SELECT
            userid,
            COUNT(*) AS total_comments_made,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    votes_cast_agg AS (
        SELECT
            userid,
            COUNT(*) AS total_votes_cast
        FROM votes
        GROUP BY userid
    ),
    votes_received_agg AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS total_votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badges_agg AS (
        SELECT
            userid,
            COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ),
    tags_agg AS (
        SELECT
            p.owneruserid,
            COUNT(DISTINCT t.id) AS total_tags_used
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_agg AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS total_post_links
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_agg AS (
        SELECT
            userid,
            COUNT(*) AS total_posthistory_entries
        FROM posthistory
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.total_posts, 0) AS total_posts,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_views, 0) AS total_views,
    COALESCE(c.total_comments_made, 0) AS total_comments_made,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(b.total_badges, 0) AS total_badges,
    COALESCE(t.total_tags_used, 0) AS total_tags_used,
    COALESCE(pl.total_post_links, 0) AS total_post_links,
    COALESCE(ph.total_posthistory_entries, 0) AS total_posthistory_entries
FROM users u
LEFT JOIN posts_agg p ON p.owneruserid = u.id
LEFT JOIN comments_agg c ON c.userid = u.id
LEFT JOIN votes_cast_agg vc ON vc.userid = u.id
LEFT JOIN votes_received_agg vr ON vr.owneruserid = u.id
LEFT JOIN badges_agg b ON b.userid = u.id
LEFT JOIN tags_agg t ON t.owneruserid = u.id
LEFT JOIN postlinks_agg pl ON pl.owneruserid = u.id
LEFT JOIN posthistory_agg ph ON ph.userid = u.id
ORDER BY total_posts DESC
LIMIT 100
