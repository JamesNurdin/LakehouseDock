WITH
    post_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS post_score_sum,
            AVG(p.score) AS post_score_avg,
            SUM(p.viewcount) AS post_view_sum,
            SUM(p.answercount) AS post_answer_sum,
            SUM(p.commentcount) AS post_comment_sum,
            SUM(p.favoritecount) AS post_favorite_sum
        FROM posts p
        GROUP BY p.owneruserid
    ),
    edit_agg AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS edit_count,
            SUM(p.score) AS edit_score_sum,
            AVG(p.score) AS edit_score_avg
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    comment_agg AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(c.score) AS comment_score_sum,
            AVG(c.score) AS comment_score_avg,
            COUNT(DISTINCT c.postid) AS distinct_post_commented
        FROM comments c
        GROUP BY c.userid
    ),
    badge_agg AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_base AS (
        SELECT
            u.id AS user_id,
            u.reputation,
            u.creationdate,
            u.views,
            u.upvotes,
            u.downvotes
        FROM users u
    )
SELECT
    ub.user_id,
    ub.reputation,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(pa.post_score_sum, 0) AS post_score_sum,
    COALESCE(pa.post_score_avg, 0) AS post_score_avg,
    COALESCE(ea.edit_count, 0) AS edit_count,
    COALESCE(ea.edit_score_sum, 0) AS edit_score_sum,
    COALESCE(ea.edit_score_avg, 0) AS edit_score_avg,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(ca.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(ca.distinct_post_commented, 0) AS distinct_post_commented,
    COALESCE(ba.badge_count, 0) AS badge_count,
    -- Combined activity metric (posts + comments + badges weighted)
    (COALESCE(pa.post_score_sum, 0) + COALESCE(ca.comment_score_sum, 0) + COALESCE(ba.badge_count, 0) * 10) AS activity_score
FROM user_base ub
LEFT JOIN post_agg pa ON ub.user_id = pa.user_id
LEFT JOIN edit_agg ea ON ub.user_id = ea.user_id
LEFT JOIN comment_agg ca ON ub.user_id = ca.user_id
LEFT JOIN badge_agg ba ON ub.user_id = ba.user_id
ORDER BY activity_score DESC
LIMIT 10
