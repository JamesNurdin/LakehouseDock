WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_cnt,
            SUM(score) AS total_score,
            AVG(score) AS avg_score,
            SUM(viewcount) AS total_views,
            SUM(answercount) AS total_answers,
            SUM(commentcount) AS total_comments_on_posts,
            SUM(favoritecount) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    post_comments AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(c.id) AS comment_cnt_on_posts
        FROM posts p
        LEFT JOIN comments c ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    post_votes AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS vote_cnt_on_posts
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    post_tags AS (
        SELECT
            p.owneruserid AS user_id,
            SUM(t.count) AS total_tag_count
        FROM posts p
        LEFT JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(id) AS badge_cnt
        FROM badges
        GROUP BY userid
    ),
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(id) AS comment_cnt_by_user
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid AS user_id,
            COUNT(id) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    user_posthistory AS (
        SELECT
            userid AS user_id,
            COUNT(id) AS posthistory_cnt
        FROM posthistory
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_cnt, 0) AS post_cnt,
    COALESCE(up.total_score, 0) AS total_score,
    COALESCE(up.avg_score, 0) AS avg_score,
    COALESCE(pc.comment_cnt_on_posts, 0) AS comments_on_own_posts,
    COALESCE(pv.vote_cnt_on_posts, 0) AS votes_on_own_posts,
    COALESCE(pt.total_tag_count, 0) AS total_tag_count,
    COALESCE(ub.badge_cnt, 0) AS badge_cnt,
    COALESCE(uc.comment_cnt_by_user, 0) AS comment_cnt_by_user,
    COALESCE(uv.votes_cast, 0) AS votes_cast,
    COALESCE(uph.posthistory_cnt, 0) AS posthistory_cnt,
    /* Derived metrics */
    CASE WHEN COALESCE(up.post_cnt, 0) > 0 THEN COALESCE(pc.comment_cnt_on_posts, 0) * 1.0 / up.post_cnt ELSE 0 END AS avg_comments_per_post,
    CASE WHEN COALESCE(up.post_cnt, 0) > 0 THEN COALESCE(pv.vote_cnt_on_posts, 0) * 1.0 / up.post_cnt ELSE 0 END AS avg_votes_per_post,
    CASE WHEN COALESCE(up.post_cnt, 0) > 0 THEN COALESCE(ub.badge_cnt, 0) * 1.0 / up.post_cnt ELSE 0 END AS badges_per_post
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN post_comments pc ON pc.user_id = u.id
LEFT JOIN post_votes pv ON pv.user_id = u.id
LEFT JOIN post_tags pt ON pt.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
WHERE COALESCE(up.post_cnt, 0) > 0
ORDER BY up.total_score DESC
LIMIT 100
