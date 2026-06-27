WITH
    user_badges AS (
        SELECT userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posts AS (
        SELECT owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            AVG(viewcount) AS avg_viewcount,
            SUM(answercount) AS total_answer_count,
            SUM(commentcount) AS total_comment_count,
            SUM(favoritecount) AS total_favorite_count
        FROM posts
        GROUP BY owneruserid
    ),
    user_edited_posts AS (
        SELECT lasteditoruserid AS userid,
            COUNT(*) AS edited_post_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    user_comments AS (
        SELECT userid,
            COUNT(*) AS comment_count,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT userid,
            COUNT(*) AS votes_cast_count,
            COALESCE(SUM(bountyamount), 0) AS total_bounty_given
        FROM votes
        GROUP BY userid
    ),
    votes_received AS (
        SELECT p.owneruserid AS userid,
            COUNT(*) AS votes_received_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory AS (
        SELECT userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    posthistory_type_for_owned_posts AS (
        SELECT p.owneruserid AS userid,
            COUNT(*) AS posthistory_type_for_owned_posts
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags AS (
        SELECT p.owneruserid AS userid,
            COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT p.owneruserid AS userid,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_related_postlinks AS (
        SELECT p.owneruserid AS userid,
            COUNT(*) AS related_postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_viewcount, 0) AS avg_viewcount,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(ue.edited_post_count, 0) AS edited_post_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(pht.posthistory_type_for_owned_posts, 0) AS posthistory_type_for_owned_posts,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(uplnk.postlink_count, 0) AS postlink_count,
    COALESCE(urel.related_postlink_count, 0) AS related_postlink_count
FROM users u
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_edited_posts ue ON ue.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN votes_received vr ON vr.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN posthistory_type_for_owned_posts pht ON pht.userid = u.id
LEFT JOIN user_tags ut ON ut.userid = u.id
LEFT JOIN user_postlinks uplnk ON uplnk.userid = u.id
LEFT JOIN user_related_postlinks urel ON urel.userid = u.id
ORDER BY u.reputation DESC
LIMIT 10
