WITH
    user_posts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS post_cnt,
            COALESCE(SUM(p.score), 0) AS post_score_sum,
            COALESCE(AVG(p.score), 0) AS post_score_avg,
            COALESCE(SUM(p.favoritecount), 0) AS total_favorites
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments_made AS (
        SELECT
            c.userid AS userid,
            COUNT(*) AS comment_cnt
        FROM comments c
        GROUP BY c.userid
    ),
    user_comments_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS comment_received_cnt
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_votes_cast AS (
        SELECT
            v.userid AS userid,
            COUNT(*) AS votes_cast_cnt
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS votes_received_cnt
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid AS userid,
            COUNT(*) AS badge_cnt
        FROM badges b
        GROUP BY b.userid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS userid,
            COUNT(*) AS posthistory_cnt
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_posthistory_on_posts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS posthistory_on_posts_cnt
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlinks_cnt
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks_related AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlinks_related_cnt
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS tag_cnt,
            COALESCE(SUM(t.count), 0) AS tag_total_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_cnt, 0) AS post_cnt,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(ucm.comment_cnt, 0) AS comment_cnt,
    COALESCE(ucr.comment_received_cnt, 0) AS comment_received_cnt,
    COALESCE(uvc.votes_cast_cnt, 0) AS votes_cast_cnt,
    COALESCE(uvr.votes_received_cnt, 0) AS votes_received_cnt,
    COALESCE(ub.badge_cnt, 0) AS badge_cnt,
    COALESCE(uph.posthistory_cnt, 0) AS posthistory_cnt,
    COALESCE(upho.posthistory_on_posts_cnt, 0) AS posthistory_on_posts_cnt,
    COALESCE(upL.postlinks_cnt, 0) AS postlinks_cnt,
    COALESCE(upR.postlinks_related_cnt, 0) AS postlinks_related_cnt,
    COALESCE(ut.tag_cnt, 0) AS tag_cnt,
    COALESCE(ut.tag_total_count, 0) AS tag_total_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments_made ucm ON ucm.userid = u.id
LEFT JOIN user_comments_received ucr ON ucr.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_posthistory_on_posts upho ON upho.userid = u.id
LEFT JOIN user_postlinks upL ON upL.userid = u.id
LEFT JOIN user_postlinks_related upR ON upR.userid = u.id
LEFT JOIN user_tags ut ON ut.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
