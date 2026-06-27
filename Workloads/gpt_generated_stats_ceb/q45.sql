WITH
    user_info AS (
        SELECT
            id,
            reputation,
            creationdate
        FROM users
    ),
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            COALESCE(SUM(score), 0) AS post_score_sum,
            COALESCE(AVG(score), 0) AS post_score_avg,
            COALESCE(SUM(viewcount), 0) AS post_view_sum
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            COALESCE(SUM(score), 0) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid,
            COUNT(*) AS votes_cast,
            COALESCE(SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END), 0) AS up_votes_cast,
            COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS down_votes_cast,
            COALESCE(SUM(bountyamount), 0) AS bounty_given
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS votes_received,
            COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS up_votes_received,
            COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS down_votes_received,
            COALESCE(SUM(v.bountyamount), 0) AS bounty_received
        FROM votes v
        JOIN posts p
            ON v.postid = p.id
        GROUP BY p.owneruserid
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
    user_links_out AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS outgoing_links
        FROM postlinks pl
        JOIN posts p
            ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_links_in AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS incoming_links
        FROM postlinks pl
        JOIN posts p
            ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p
            ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.up_votes_cast, 0) AS up_votes_cast,
    COALESCE(uvc.down_votes_cast, 0) AS down_votes_cast,
    COALESCE(uvc.bounty_given, 0) AS bounty_given,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.up_votes_received, 0) AS up_votes_received,
    COALESCE(uvr.down_votes_received, 0) AS down_votes_received,
    COALESCE(uvr.bounty_received, 0) AS bounty_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ul_out.outgoing_links, 0) AS outgoing_links,
    COALESCE(ul_in.incoming_links, 0) AS incoming_links,
    COALESCE(ut.tag_count, 0) AS tag_count,
    (
        COALESCE(up.post_count, 0) * 5
        + COALESCE(uc.comment_count, 0) * 2
        + COALESCE(uvc.votes_cast, 0) * 1
        + COALESCE(uvr.votes_received, 0) * 3
        + COALESCE(ub.badge_count, 0) * 4
        + COALESCE(uph.posthistory_count, 0) * 1
        + COALESCE(ul_out.outgoing_links, 0) * 1
        + COALESCE(ul_in.incoming_links, 0) * 1
    ) AS engagement_score
FROM user_info u
LEFT JOIN user_posts up
    ON up.userid = u.id
LEFT JOIN user_comments uc
    ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc
    ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr
    ON uvr.userid = u.id
LEFT JOIN user_badges ub
    ON ub.userid = u.id
LEFT JOIN user_posthistory uph
    ON uph.userid = u.id
LEFT JOIN user_links_out ul_out
    ON ul_out.userid = u.id
LEFT JOIN user_links_in ul_in
    ON ul_in.userid = u.id
LEFT JOIN user_tags ut
    ON ut.userid = u.id
ORDER BY engagement_score DESC
LIMIT 100
