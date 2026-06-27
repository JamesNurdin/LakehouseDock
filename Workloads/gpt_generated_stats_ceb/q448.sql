WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_posts,
            COALESCE(SUM(score), 0) AS total_post_score,
            COALESCE(SUM(viewcount), 0) AS total_viewcount
        FROM posts
        GROUP BY owneruserid
    ),
    user_questions AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_questions
        FROM posts
        WHERE posttypeid = 1
        GROUP BY owneruserid
    ),
    user_answers AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_answers
        FROM posts
        WHERE posttypeid = 2
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_comments,
            COALESCE(SUM(score), 0) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_votes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_edits
        FROM posthistory
        GROUP BY userid
    ),
    user_tag_excerpts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_tag_excerpts
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_outbound_links AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_outbound_links
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_inbound_links AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_inbound_links
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.total_posts, 0) AS total_posts,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(q.total_questions, 0) AS total_questions,
    COALESCE(a.total_answers, 0) AS total_answers,
    COALESCE(c.total_comments, 0) AS total_comments,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(b.total_badges, 0) AS total_badges,
    COALESCE(e.total_edits, 0) AS total_edits,
    COALESCE(t.total_tag_excerpts, 0) AS total_tag_excerpts,
    COALESCE(ol.total_outbound_links, 0) AS total_outbound_links,
    COALESCE(il.total_inbound_links, 0) AS total_inbound_links
FROM users u
LEFT JOIN user_posts p ON u.id = p.user_id
LEFT JOIN user_questions q ON u.id = q.user_id
LEFT JOIN user_answers a ON u.id = a.user_id
LEFT JOIN user_comments c ON u.id = c.user_id
LEFT JOIN user_votes_cast vc ON u.id = vc.user_id
LEFT JOIN user_votes_received vr ON u.id = vr.user_id
LEFT JOIN user_badges b ON u.id = b.user_id
LEFT JOIN user_edits e ON u.id = e.user_id
LEFT JOIN user_tag_excerpts t ON u.id = t.user_id
LEFT JOIN user_outbound_links ol ON u.id = ol.user_id
LEFT JOIN user_inbound_links il ON u.id = il.user_id
ORDER BY u.reputation DESC
LIMIT 20
