WITH
    user_info AS (
        SELECT
            id AS userid,
            reputation,
            creationdate,
            views,
            upvotes,
            downvotes
        FROM users
    ),
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS post_score_sum,
            AVG(score) AS post_score_avg,
            SUM(viewcount) AS post_view_sum,
            SUM(answercount) AS total_answer_count,
            SUM(commentcount) AS total_comment_count,
            SUM(favoritecount) AS total_favorite_count
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            SUM(score) AS comment_score_sum,
            AVG(score) AS comment_score_avg
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posthistory AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    user_postlinks_source AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS source_link_count
        FROM postlinks pl
        JOIN posts p
            ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks_related AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS related_link_count
        FROM postlinks pl
        JOIN posts p
            ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ui.userid,
    ui.reputation,
    ui.creationdate,
    ui.views,
    ui.upvotes,
    ui.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.upvote_cast, 0) AS upvote_cast,
    COALESCE(uv.downvote_cast, 0) AS downvote_cast,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(uls.source_link_count, 0) AS source_link_count,
    COALESCE(ulr.related_link_count, 0) AS related_link_count,
    CASE WHEN COALESCE(uc.comment_count, 0) = 0 THEN NULL
         ELSE COALESCE(up.post_count, 0) * 1.0 / uc.comment_count END AS posts_per_comment
FROM user_info ui
LEFT JOIN user_posts up ON ui.userid = up.userid
LEFT JOIN user_comments uc ON ui.userid = uc.userid
LEFT JOIN user_votes uv ON ui.userid = uv.userid
LEFT JOIN user_badges ub ON ui.userid = ub.userid
LEFT JOIN user_posthistory uph ON ui.userid = uph.userid
LEFT JOIN user_postlinks_source uls ON ui.userid = uls.userid
LEFT JOIN user_postlinks_related ulr ON ui.userid = ulr.userid
ORDER BY ui.reputation DESC
LIMIT 100
