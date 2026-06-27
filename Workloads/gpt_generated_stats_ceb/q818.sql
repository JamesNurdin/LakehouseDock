SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.upvote_count, 0) AS upvote_count,
    COALESCE(uv.downvote_count, 0) AS downvote_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ul.link_count, 0) AS link_count,
    COALESCE(ut.tag_excerpt_post_count, 0) AS tag_excerpt_post_count
FROM users u
LEFT JOIN (
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
) up ON u.id = up.userid
LEFT JOIN (
    SELECT
        lasteditoruserid AS userid,
        COUNT(*) AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
) ue ON u.id = ue.userid
LEFT JOIN (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
) uc ON u.id = uc.userid
LEFT JOIN (
    SELECT
        userid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY userid
) uv ON u.id = uv.userid
LEFT JOIN (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
) ub ON u.id = ub.userid
LEFT JOIN (
    SELECT
        userid,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
) uph ON u.id = uph.userid
LEFT JOIN (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
) ul ON u.id = ul.userid
LEFT JOIN (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS tag_excerpt_post_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
) ut ON u.id = ut.userid
ORDER BY u.reputation DESC
LIMIT 100
