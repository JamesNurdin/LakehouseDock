WITH
    users_base AS (
        SELECT
            id AS user_id,
            reputation,
            creationdate,
            views,
            upvotes,
            downvotes
        FROM users
    ),
    posts_agg AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            AVG(viewcount) AS avg_viewcount,
            SUM(answercount) AS total_answers,
            SUM(commentcount) AS total_comments_on_posts
        FROM posts
        GROUP BY owneruserid
    ),
    comments_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    votes_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS vote_count,
            COUNT(DISTINCT postid) AS distinct_posts_voted,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
        FROM votes
        GROUP BY userid
    ),
    badges_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    posthistory_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_events
        FROM posthistory
        GROUP BY userid
    ),
    postlinks_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    tags_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_viewcount, 0) AS avg_viewcount,
    COALESCE(p.total_answers, 0) AS total_answers,
    COALESCE(p.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.distinct_posts_voted, 0) AS distinct_posts_voted,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_events, 0) AS posthistory_events,
    COALESCE(pl.postlink_count, 0) AS postlink_count,
    COALESCE(tg.tag_count, 0) AS tag_count,
    (COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0) + COALESCE(v.vote_count, 0) + COALESCE(b.badge_count, 0)) AS activity_score
FROM users_base u
LEFT JOIN posts_agg p ON u.user_id = p.user_id
LEFT JOIN comments_agg c ON u.user_id = c.user_id
LEFT JOIN votes_agg v ON u.user_id = v.user_id
LEFT JOIN badges_agg b ON u.user_id = b.user_id
LEFT JOIN posthistory_agg ph ON u.user_id = ph.user_id
LEFT JOIN postlinks_agg pl ON u.user_id = pl.user_id
LEFT JOIN tags_agg tg ON u.user_id = tg.user_id
ORDER BY activity_score DESC
LIMIT 100
