WITH
    -- Base user information
    user_base AS (
        SELECT
            id,
            reputation,
            creationdate,
            views,
            upvotes,
            downvotes
        FROM users
    ),
    -- Posts created by each user (owner)
    posts_agg AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_views,
            SUM(answercount) AS total_answers,
            SUM(commentcount) AS total_comments_on_posts,
            SUM(favoritecount) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    -- Comments made by each user
    comments_agg AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            SUM(score) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    -- Votes cast by each user (including breakdown of vote types)
    votes_agg AS (
        SELECT
            userid,
            COUNT(*) AS votes_cast,
            COUNT(CASE WHEN votetypeid = 1 THEN 1 END) AS upvote_cast,
            COUNT(CASE WHEN votetypeid = 2 THEN 1 END) AS downvote_cast
        FROM votes
        GROUP BY userid
    ),
    -- Badges earned by each user
    badges_agg AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    -- Post‑history events performed by each user
    posthistory_agg AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_events
        FROM posthistory
        GROUP BY userid
    ),
    -- Tags that appear on posts owned by each user
    tags_agg AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0)               AS post_count,
    COALESCE(p.total_post_score, 0)         AS total_post_score,
    COALESCE(p.total_views, 0)              AS total_views,
    COALESCE(p.total_answers, 0)            AS total_answers,
    COALESCE(p.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(p.total_favorites, 0)          AS total_favorites,
    COALESCE(c.comment_count, 0)            AS comment_count,
    COALESCE(c.comment_score_sum, 0)        AS comment_score_sum,
    COALESCE(v.votes_cast, 0)               AS votes_cast,
    COALESCE(v.upvote_cast, 0)              AS upvote_cast,
    COALESCE(v.downvote_cast, 0)            AS downvote_cast,
    COALESCE(b.badge_count, 0)              AS badge_count,
    COALESCE(ph.posthistory_events, 0)      AS posthistory_events,
    COALESCE(t.tag_count, 0)                AS tag_count,
    -- Derived metrics
    CASE WHEN COALESCE(p.post_count, 0) = 0 THEN NULL
         ELSE COALESCE(p.total_post_score, 0) / NULLIF(COALESCE(p.post_count, 0), 0)
    END                                      AS avg_post_score,
    CASE WHEN COALESCE(c.comment_count, 0) = 0 THEN NULL
         ELSE COALESCE(c.comment_score_sum, 0) / NULLIF(COALESCE(c.comment_count, 0), 0)
    END                                      AS avg_comment_score,
    CASE WHEN u.downvotes = 0 THEN NULL
         ELSE u.upvotes / NULLIF(u.downvotes, 0)
    END                                      AS upvote_to_downvote_ratio
FROM user_base u
LEFT JOIN posts_agg p      ON u.id = p.userid
LEFT JOIN comments_agg c   ON u.id = c.userid
LEFT JOIN votes_agg v      ON u.id = v.userid
LEFT JOIN badges_agg b     ON u.id = b.userid
LEFT JOIN posthistory_agg ph ON u.id = ph.userid
LEFT JOIN tags_agg t       ON u.id = t.userid
ORDER BY u.reputation DESC
LIMIT 20
