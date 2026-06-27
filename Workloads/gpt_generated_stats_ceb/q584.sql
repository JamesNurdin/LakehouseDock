WITH
    user_posts AS (
        SELECT owneruserid AS userid,
               COUNT(*) AS total_posts_owned
        FROM posts
        GROUP BY owneruserid
    ),
    user_last_edits AS (
        SELECT lasteditoruserid AS userid,
               COUNT(*) AS total_posts_last_edited
        FROM posts
        GROUP BY lasteditoruserid
    ),
    user_comments AS (
        SELECT userid,
               COUNT(*) AS total_comments_made,
               SUM(score) AS total_comment_score,
               COUNT(DISTINCT postid) AS distinct_commented_posts
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT userid,
               COUNT(*) AS total_votes_cast,
               SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS total_upvotes_cast,
               SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS total_downvotes_cast,
               SUM(bountyamount) AS total_bounty_given
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT p.owneruserid AS userid,
               COUNT(v.id) AS total_votes_received,
               SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS total_upvotes_received,
               SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS total_downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory AS (
        SELECT userid,
               COUNT(*) AS total_posthistory_events
        FROM posthistory
        GROUP BY userid
    ),
    user_posthistory_on_owned AS (
        SELECT p.owneruserid AS userid,
               COUNT(ph.id) AS total_posthistory_on_owned_posts
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks_out AS (
        SELECT p.owneruserid AS userid,
               COUNT(pl.id) AS total_outbound_links
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks_in AS (
        SELECT p.owneruserid AS userid,
               COUNT(pl.id) AS total_inbound_links
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT u.id,
       u.reputation,
       COALESCE(up.total_posts_owned, 0)               AS total_posts_owned,
       COALESCE(ue.total_posts_last_edited, 0)        AS total_posts_last_edited,
       COALESCE(uc.total_comments_made, 0)           AS total_comments_made,
       COALESCE(uc.total_comment_score, 0)           AS total_comment_score,
       COALESCE(uvc.total_votes_cast, 0)             AS total_votes_cast,
       COALESCE(uvc.total_upvotes_cast, 0)           AS total_upvotes_cast,
       COALESCE(uvc.total_downvotes_cast, 0)         AS total_downvotes_cast,
       COALESCE(uvc.total_bounty_given, 0)           AS total_bounty_given,
       COALESCE(uvr.total_votes_received, 0)         AS total_votes_received,
       COALESCE(uvr.total_upvotes_received, 0)       AS total_upvotes_received,
       COALESCE(uvr.total_downvotes_received, 0)     AS total_downvotes_received,
       COALESCE(uph.total_posthistory_events, 0)    AS total_posthistory_events,
       COALESCE(uph_on.total_posthistory_on_owned_posts, 0) AS total_posthistory_on_owned_posts,
       COALESCE(upout.total_outbound_links, 0)       AS total_outbound_links,
       COALESCE(upin.total_inbound_links, 0)         AS total_inbound_links
FROM users u
LEFT JOIN user_posts up          ON u.id = up.userid
LEFT JOIN user_last_edits ue    ON u.id = ue.userid
LEFT JOIN user_comments uc      ON u.id = uc.userid
LEFT JOIN user_votes_cast uvc   ON u.id = uvc.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.userid
LEFT JOIN user_posthistory uph ON u.id = uph.userid
LEFT JOIN user_posthistory_on_owned uph_on ON u.id = uph_on.userid
LEFT JOIN user_postlinks_out upout ON u.id = upout.userid
LEFT JOIN user_postlinks_in upin   ON u.id = upin.userid
ORDER BY total_posts_owned DESC, total_votes_received DESC
LIMIT 100
