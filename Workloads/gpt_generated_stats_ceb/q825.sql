WITH
    user_badge_counts AS (
        SELECT userid,
               COUNT(id) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_comment_counts AS (
        SELECT userid,
               COUNT(id) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    user_post_stats AS (
        SELECT owneruserid AS userid,
               COUNT(id) AS post_count,
               SUM(score) AS total_post_score,
               AVG(score) AS avg_post_score,
               SUM(viewcount) AS total_views,
               SUM(answercount) AS total_answers,
               SUM(favoritecount) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    user_votes_cast AS (
        SELECT userid,
               COUNT(id) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT p.owneruserid AS userid,
               COUNT(v.id) AS votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory_counts AS (
        SELECT userid,
               COUNT(id) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    user_last_edit_counts AS (
        SELECT lasteditoruserid AS userid,
               COUNT(id) AS last_edit_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    user_tag_counts AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_source_link_counts AS (
        SELECT p.owneruserid AS userid,
               COUNT(pl.id) AS source_link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_target_link_counts AS (
        SELECT p.owneruserid AS userid,
               COUNT(pl.id) AS target_link_count
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(ubc.badge_count, 0) AS badge_count,
    COALESCE(ucc.comment_count, 0) AS comment_count,
    COALESCE(ups.post_count, 0) AS post_count,
    COALESCE(ups.total_post_score, 0) AS total_post_score,
    COALESCE(ups.avg_post_score, 0) AS avg_post_score,
    COALESCE(ups.total_views, 0) AS total_views,
    COALESCE(ups.total_answers, 0) AS total_answers,
    COALESCE(ups.total_favorites, 0) AS total_favorites,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uphc.posthistory_count, 0) AS posthistory_count,
    COALESCE(ulec.last_edit_count, 0) AS last_edit_count,
    COALESCE(utc.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(uslc.source_link_count, 0) AS source_link_count,
    COALESCE(utlc.target_link_count, 0) AS target_link_count
FROM users u
LEFT JOIN user_badge_counts ubc ON ubc.userid = u.id
LEFT JOIN user_comment_counts ucc ON ucc.userid = u.id
LEFT JOIN user_post_stats ups ON ups.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_posthistory_counts uphc ON uphc.userid = u.id
LEFT JOIN user_last_edit_counts ulec ON ulec.userid = u.id
LEFT JOIN user_tag_counts utc ON utc.userid = u.id
LEFT JOIN user_source_link_counts uslc ON uslc.userid = u.id
LEFT JOIN user_target_link_counts utlc ON utlc.userid = u.id
ORDER BY badge_count DESC, total_post_score DESC
LIMIT 10
