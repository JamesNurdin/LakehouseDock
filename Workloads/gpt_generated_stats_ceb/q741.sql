WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_viewcount,
            SUM(answercount) AS total_answer_count,
            SUM(commentcount) AS total_comment_count,
            SUM(favoritecount) AS total_favorite_count
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
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
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
            lasteditoruserid AS user_id,
            COUNT(*) AS edited_post_count
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    user_history AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    user_outbound_links AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS outbound_link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_inbound_links AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS inbound_link_count
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_tag_excerpts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tag_excerpt_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.total_answer_count, 0) AS total_answer_count,
    COALESCE(p.total_comment_count, 0) AS total_comment_count,
    COALESCE(p.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edited_post_count, 0) AS edited_post_count,
    COALESCE(h.posthistory_count, 0) AS posthistory_count,
    COALESCE(ol.outbound_link_count, 0) AS outbound_link_count,
    COALESCE(il.inbound_link_count, 0) AS inbound_link_count,
    COALESCE(te.tag_excerpt_count, 0) AS tag_excerpt_count,
    CASE WHEN COALESCE(p.post_count, 0) = 0 THEN 0
         ELSE COALESCE(p.total_post_score, 0) * 1.0 / COALESCE(p.post_count, 1)
    END AS avg_post_score
FROM users u
LEFT JOIN user_posts p ON p.user_id = u.id
LEFT JOIN user_comments c ON c.user_id = u.id
LEFT JOIN user_votes v ON v.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_edits e ON e.user_id = u.id
LEFT JOIN user_history h ON h.user_id = u.id
LEFT JOIN user_outbound_links ol ON ol.user_id = u.id
LEFT JOIN user_inbound_links il ON il.user_id = u.id
LEFT JOIN user_tag_excerpts te ON te.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
