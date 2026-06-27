WITH
    user_posts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS post_count,
            COALESCE(SUM(p.score), 0) AS post_score_sum,
            COALESCE(AVG(p.score), 0) AS post_score_avg,
            COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
            COALESCE(SUM(p.answercount), 0) AS total_answercount,
            COALESCE(SUM(p.commentcount), 0) AS total_commentcount,
            COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount,
            COUNT(CASE WHEN p.lasteditoruserid IS NOT NULL AND p.lasteditoruserid <> p.owneruserid THEN 1 END) AS edited_by_others_count
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT
            p.lasteditoruserid AS userid,
            COUNT(*) AS edited_posts_count
        FROM posts p
        WHERE p.lasteditoruserid IS NOT NULL
        GROUP BY p.lasteditoruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS userid,
            COUNT(*) AS comment_count,
            COALESCE(SUM(c.score), 0) AS comment_score_sum,
            COALESCE(AVG(c.score), 0) AS comment_score_avg
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes AS (
        SELECT
            v.userid AS userid,
            COUNT(*) AS vote_count,
            COALESCE(SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END), 0) AS total_bounty_amount,
            COUNT(DISTINCT v.postid) AS distinct_posts_voted
        FROM votes v
        GROUP BY v.userid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS userid,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p
            ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p
            ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_commentcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(up.edited_by_others_count, 0) AS edited_by_others_count,
    COALESCE(ue.edited_posts_count, 0) AS edited_posts_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uc.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(v.distinct_posts_voted, 0) AS distinct_posts_voted,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(tg.tag_count, 0) AS tag_count,
    COALESCE(pl.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up
    ON up.userid = u.id
LEFT JOIN user_edits ue
    ON ue.userid = u.id
LEFT JOIN user_comments uc
    ON uc.userid = u.id
LEFT JOIN user_votes v
    ON v.userid = u.id
LEFT JOIN user_posthistory ph
    ON ph.userid = u.id
LEFT JOIN user_tags tg
    ON tg.userid = u.id
LEFT JOIN user_postlinks pl
    ON pl.userid = u.id
ORDER BY u.reputation DESC
LIMIT 20
