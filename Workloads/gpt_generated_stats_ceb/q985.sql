WITH
    user_info AS (
        SELECT
            id AS user_id,
            reputation,
            upvotes,
            downvotes,
            creationdate
        FROM users
    ),
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_views
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS vote_cast_count,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast,
            SUM(COALESCE(bountyamount, 0)) AS total_bounty_given
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS edit_count
        FROM posthistory
        GROUP BY userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_links AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.user_id,
    u.reputation,
    u.upvotes,
    u.downvotes,
    u.creationdate,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_views, 0) AS total_views,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(v.upvote_cast, 0) AS upvote_cast,
    COALESCE(v.downvote_cast, 0) AS downvote_cast,
    COALESCE(v.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(tg.tag_count, 0) AS tag_count,
    COALESCE(l.link_count, 0) AS link_count
FROM user_info u
LEFT JOIN user_posts p   ON u.user_id = p.user_id
LEFT JOIN user_comments c ON u.user_id = c.user_id
LEFT JOIN user_votes v    ON u.user_id = v.user_id
LEFT JOIN user_badges b   ON u.user_id = b.user_id
LEFT JOIN user_edits e    ON u.user_id = e.user_id
LEFT JOIN user_tags tg    ON u.user_id = tg.user_id
LEFT JOIN user_links l    ON u.user_id = l.user_id
ORDER BY u.reputation DESC
LIMIT 100
