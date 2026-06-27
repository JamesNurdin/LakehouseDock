WITH
    user_base AS (
        SELECT u.id AS user_id,
               u.reputation
        FROM users u
    ),
    posts_agg AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS post_count,
               SUM(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
               SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
               COALESCE(SUM(p.score), 0) AS total_post_score,
               COALESCE(SUM(p.viewcount), 0) AS total_views,
               COALESCE(SUM(p.favoritecount), 0) AS total_favorites
        FROM posts p
        GROUP BY p.owneruserid
    ),
    comments_agg AS (
        SELECT c.userid AS user_id,
               COUNT(*) AS comment_count
        FROM comments c
        GROUP BY c.userid
    ),
    votes_agg AS (
        SELECT v.userid AS user_id,
               COUNT(*) AS vote_count
        FROM votes v
        GROUP BY v.userid
    ),
    badges_agg AS (
        SELECT b.userid AS user_id,
               COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    posthistory_agg AS (
        SELECT ph.userid AS user_id,
               COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    )
SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(p.post_count, 0)               AS post_count,
    COALESCE(p.question_count, 0)           AS question_count,
    COALESCE(p.answer_count, 0)             AS answer_count,
    COALESCE(p.total_post_score, 0)         AS total_post_score,
    COALESCE(p.total_views, 0)              AS total_views,
    COALESCE(p.total_favorites, 0)          AS total_favorites,
    COALESCE(c.comment_count, 0)            AS comment_count,
    COALESCE(v.vote_count, 0)               AS vote_count,
    COALESCE(b.badge_count, 0)              AS badge_count,
    COALESCE(ph.posthistory_count, 0)       AS posthistory_count,
    CASE WHEN COALESCE(p.post_count, 0) > 0 THEN p.total_post_score / p.post_count END AS avg_post_score,
    CASE WHEN COALESCE(p.post_count, 0) > 0 THEN p.total_views / p.post_count END    AS avg_views_per_post,
    CASE WHEN COALESCE(p.post_count, 0) > 0 THEN b.badge_count / p.post_count END   AS badges_per_post,
    CASE WHEN COALESCE(p.post_count, 0) > 0 THEN c.comment_count / p.post_count END AS comments_per_post,
    ROW_NUMBER() OVER (ORDER BY ub.reputation DESC, COALESCE(p.post_count, 0) DESC) AS reputation_rank
FROM user_base ub
LEFT JOIN posts_agg p          ON p.user_id = ub.user_id
LEFT JOIN comments_agg c       ON c.user_id = ub.user_id
LEFT JOIN votes_agg v          ON v.user_id = ub.user_id
LEFT JOIN badges_agg b         ON b.user_id = ub.user_id
LEFT JOIN posthistory_agg ph   ON ph.user_id = ub.user_id
WHERE COALESCE(p.post_count, 0) > 0
ORDER BY ub.reputation DESC, COALESCE(p.post_count, 0) DESC
LIMIT 100
