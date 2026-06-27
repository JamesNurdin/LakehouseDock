WITH
    user_base AS (
        SELECT
            id,
            reputation,
            creationdate
        FROM users
    ),
    posts_agg AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            COALESCE(SUM(score), 0) AS post_score_sum,
            COALESCE(SUM(viewcount), 0) AS post_viewcount_sum,
            COALESCE(SUM(answercount), 0) AS post_answer_sum,
            COALESCE(SUM(commentcount), 0) AS post_comment_sum,
            COALESCE(SUM(favoritecount), 0) AS post_favorite_sum
        FROM posts
        GROUP BY owneruserid
    ),
    comments_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            COALESCE(SUM(score), 0) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    votes_cast_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS vote_cast_count,
            COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvote_cast_count,
            COALESCE(SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvote_cast_count
        FROM votes
        GROUP BY userid
    ),
    votes_received_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS vote_received_count,
            COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvote_received_count,
            COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvote_received_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
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
            COUNT(*) AS post_history_count
        FROM posthistory
        GROUP BY userid
    ),
    tags_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_agg AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.id AS user_id,
    ub.reputation,
    ub.creationdate,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(pa.post_score_sum, 0) AS post_score_sum,
    COALESCE(pa.post_viewcount_sum, 0) AS post_viewcount_sum,
    COALESCE(pa.post_answer_sum, 0) AS post_answer_sum,
    COALESCE(pa.post_comment_sum, 0) AS post_comment_sum,
    COALESCE(pa.post_favorite_sum, 0) AS post_favorite_sum,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(vca.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vca.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(vca.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(vra.vote_received_count, 0) AS vote_received_count,
    COALESCE(vra.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(vra.downvote_received_count, 0) AS downvote_received_count,
    COALESCE(ba.badge_count, 0) AS badge_count,
    COALESCE(pha.post_history_count, 0) AS post_history_count,
    COALESCE(ta.tag_count, 0) AS tag_count,
    COALESCE(pla.post_link_count, 0) AS post_link_count
FROM user_base ub
LEFT JOIN posts_agg pa ON pa.user_id = ub.id
LEFT JOIN comments_agg ca ON ca.user_id = ub.id
LEFT JOIN votes_cast_agg vca ON vca.user_id = ub.id
LEFT JOIN votes_received_agg vra ON vra.user_id = ub.id
LEFT JOIN badges_agg ba ON ba.user_id = ub.id
LEFT JOIN posthistory_agg pha ON pha.user_id = ub.id
LEFT JOIN tags_agg ta ON ta.user_id = ub.id
LEFT JOIN postlinks_agg pla ON pla.user_id = ub.id
ORDER BY post_score_sum DESC
LIMIT 100
