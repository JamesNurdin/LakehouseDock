WITH
    user_posts AS (
        SELECT owneruserid AS userid,
               COUNT(*) AS post_count,
               AVG(score) AS avg_post_score,
               SUM(viewcount) AS total_views
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT userid,
               COUNT(*) AS comment_count,
               SUM(score) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT userid,
               COUNT(*) AS votes_cast,
               SUM(bountyamount) AS total_bounty_given
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS votes_received,
               SUM(v.bountyamount) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_edits_made AS (
        SELECT userid,
               COUNT(*) AS edit_count_made
        FROM posthistory
        GROUP BY userid
    ),
    user_edits_received AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS edit_count_received
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    user_links_outgoing AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS outgoing_links
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_links_incoming AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS incoming_links
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.avg_post_score, 0) AS avg_post_score,
       COALESCE(up.total_views, 0) AS total_views,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
       COALESCE(uem.edit_count_made, 0) AS edit_count_made,
       COALESCE(uer.edit_count_received, 0) AS edit_count_received,
       COALESCE(ulo.outgoing_links, 0) AS outgoing_links,
       COALESCE(uli.incoming_links, 0) AS incoming_links,
       COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast uvc ON u.id = uvc.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.userid
LEFT JOIN user_edits_made uem ON u.id = uem.userid
LEFT JOIN user_edits_received uer ON u.id = uer.userid
LEFT JOIN user_links_outgoing ulo ON u.id = ulo.userid
LEFT JOIN user_links_incoming uli ON u.id = uli.userid
LEFT JOIN user_tags ut ON u.id = ut.userid
ORDER BY u.reputation DESC
LIMIT 100
