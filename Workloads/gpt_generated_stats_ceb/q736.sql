WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_viewcount,
            SUM(favoritecount) AS total_favoritecount,
            SUM(answercount) AS total_answercount,
            SUM(commentcount) AS total_commentcount
        FROM posts
        GROUP BY owneruserid
    ),
    user_tags AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(DISTINCT tags.id) AS tag_count
        FROM tags
        JOIN posts ON tags.excerptpostid = posts.id
        GROUP BY posts.owneruserid
    ),
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_made_count
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast_count
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
    user_posthistory AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(*) AS post_history_count
        FROM posthistory
        JOIN posts ON posthistory.posthistorytypeid = posts.id
        GROUP BY posts.owneruserid
    ),
    user_postlinks_out AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(*) AS outgoing_link_count
        FROM postlinks
        JOIN posts ON postlinks.postid = posts.id
        GROUP BY posts.owneruserid
    ),
    user_postlinks_in AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(*) AS incoming_link_count
        FROM postlinks
        JOIN posts ON postlinks.relatedpostid = posts.id
        GROUP BY posts.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(p.total_answercount, 0) AS total_answercount,
    COALESCE(p.total_commentcount, 0) AS total_commentcount,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(c.comment_made_count, 0) AS comment_made_count,
    COALESCE(v.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.post_history_count, 0) AS post_history_count,
    COALESCE(pl_out.outgoing_link_count, 0) AS outgoing_link_count,
    COALESCE(pl_in.incoming_link_count, 0) AS incoming_link_count
FROM users u
LEFT JOIN user_posts p ON u.id = p.user_id
LEFT JOIN user_tags t ON u.id = t.user_id
LEFT JOIN user_comments c ON u.id = c.user_id
LEFT JOIN user_votes v ON u.id = v.user_id
LEFT JOIN user_badges b ON u.id = b.user_id
LEFT JOIN user_posthistory ph ON u.id = ph.user_id
LEFT JOIN user_postlinks_out pl_out ON u.id = pl_out.user_id
LEFT JOIN user_postlinks_in pl_in ON u.id = pl_in.user_id
WHERE u.reputation > 1000
ORDER BY post_count DESC
LIMIT 100
