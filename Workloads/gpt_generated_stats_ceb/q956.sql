WITH
    user_posts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(p.score) AS post_score_sum,
            AVG(p.score) AS post_score_avg,
            SUM(p.viewcount) AS post_view_sum,
            SUM(p.answercount) AS answer_count_sum,
            SUM(p.commentcount) AS comment_count_sum,
            SUM(p.favoritecount) AS favorite_count_sum
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS userid,
            COUNT(*) AS comment_count,
            SUM(c.score) AS comment_score_sum
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes AS (
        SELECT
            v.userid AS userid,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
        FROM votes v
        GROUP BY v.userid
    ),
    user_badges AS (
        SELECT
            b.userid AS userid,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS userid,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_tag_counts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_link_counts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS link_count
        FROM posts p
        JOIN postlinks pl ON pl.postid = p.id
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
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(up.answer_count_sum, 0) AS answer_count_sum,
    COALESCE(up.comment_count_sum, 0) AS post_comment_count,
    COALESCE(up.favorite_count_sum, 0) AS favorite_count_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.upvote_count, 0) AS upvote_count,
    COALESCE(uv.downvote_count, 0) AS downvote_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(ul.link_count, 0) AS link_count
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes uv ON u.id = uv.userid
LEFT JOIN user_badges ub ON u.id = ub.userid
LEFT JOIN user_posthistory uph ON u.id = uph.userid
LEFT JOIN user_tag_counts ut ON u.id = ut.userid
LEFT JOIN user_link_counts ul ON u.id = ul.userid
ORDER BY post_count DESC, comment_count DESC
LIMIT 50
