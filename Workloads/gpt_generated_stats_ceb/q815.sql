WITH
    users_cte AS (
        SELECT
            id AS user_id,
            reputation
        FROM users
    ),
    posts_agg AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_posts,
            AVG(score) AS avg_post_score,
            SUM(answercount) AS total_answers
        FROM posts
        GROUP BY owneruserid
    ),
    comments_written AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_comments_written
        FROM comments
        GROUP BY userid
    ),
    comments_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_comments_received
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_votes_cast
        FROM votes
        GROUP BY userid
    ),
    votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_votes_received
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
    postlinks_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_postlinks
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    tags_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS total_tagged_posts
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.user_id,
    u.reputation,
    COALESCE(p.total_posts, 0) AS total_posts,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_answers, 0) AS total_answers,
    COALESCE(cw.total_comments_written, 0) AS total_comments_written,
    COALESCE(cr.total_comments_received, 0) AS total_comments_received,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(b.total_badges, 0) AS total_badges,
    COALESCE(pl.total_postlinks, 0) AS total_postlinks,
    COALESCE(t.total_tagged_posts, 0) AS total_tagged_posts
FROM users_cte u
LEFT JOIN posts_agg p ON u.user_id = p.user_id
LEFT JOIN comments_written cw ON u.user_id = cw.user_id
LEFT JOIN comments_received cr ON u.user_id = cr.user_id
LEFT JOIN votes_cast vc ON u.user_id = vc.user_id
LEFT JOIN votes_received vr ON u.user_id = vr.user_id
LEFT JOIN badges_agg b ON u.user_id = b.user_id
LEFT JOIN postlinks_agg pl ON u.user_id = pl.user_id
LEFT JOIN tags_agg t ON u.user_id = t.user_id
ORDER BY total_posts DESC
LIMIT 100
