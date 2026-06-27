WITH
    -- Base user information
    user_base AS (
        SELECT
            id,
            reputation,
            creationdate
        FROM users
    ),
    -- Posts owned by each user
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS posts_owned,
            AVG(p.score) AS avg_score_owned,
            SUM(p.viewcount) AS total_views_owned
        FROM posts p
        GROUP BY p.owneruserid
    ),
    -- Distinct posts edited by each user (last editor)
    user_edits AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(DISTINCT p.id) AS posts_edited
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    -- Comments made by each user
    user_comments AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comments_made,
            AVG(c.score) AS avg_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    -- Votes cast by each user
    user_votes AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS votes_cast,
            COUNT(DISTINCT v.postid) AS distinct_posts_voted,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    -- Badges earned by each user
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badges_earned
        FROM badges b
        GROUP BY b.userid
    )
SELECT
    ub.id AS user_id,
    ub.reputation,
    ub.creationdate,
    ROW_NUMBER() OVER (ORDER BY ub.reputation DESC) AS reputation_rank,
    COALESCE(up.posts_owned, 0) AS posts_owned,
    COALESCE(up.avg_score_owned, 0) AS avg_score_owned,
    COALESCE(up.total_views_owned, 0) AS total_views_owned,
    COALESCE(ue.posts_edited, 0) AS posts_edited,
    COALESCE(uc.comments_made, 0) AS comments_made,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uv.votes_cast, 0) AS votes_cast,
    COALESCE(uv.distinct_posts_voted, 0) AS distinct_posts_voted,
    COALESCE(uv.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uv.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(ubad.badges_earned, 0) AS badges_earned
FROM user_base ub
LEFT JOIN user_posts up   ON up.user_id   = ub.id
LEFT JOIN user_edits ue   ON ue.user_id   = ub.id
LEFT JOIN user_comments uc ON uc.user_id   = ub.id
LEFT JOIN user_votes uv   ON uv.user_id   = ub.id
LEFT JOIN user_badges ubad ON ubad.user_id = ub.id
ORDER BY ub.reputation DESC
LIMIT 100
