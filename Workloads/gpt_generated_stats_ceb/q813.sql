WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS total_posts_owned,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           AVG(p.score) AS avg_post_score
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS total_votes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS total_votes_received,
           COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_edits_made AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS total_edits_made
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_last_editor_counts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS times_last_editor
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_distinct_posts_edited AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT p.id) AS distinct_posts_edited
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    LEFT JOIN posts p
        ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT u.id AS user_id,
       u.reputation,
       up.total_posts_owned,
       up.total_post_score,
       up.avg_post_score,
       uv.total_votes_cast,
       ur.total_votes_received,
       ur.total_bounty_received,
       ue.total_edits_made,
       ul.times_last_editor,
       ud.distinct_posts_edited
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN user_votes_cast uv
    ON uv.user_id = u.id
LEFT JOIN user_votes_received ur
    ON ur.user_id = u.id
LEFT JOIN user_edits_made ue
    ON ue.user_id = u.id
LEFT JOIN user_last_editor_counts ul
    ON ul.user_id = u.id
LEFT JOIN user_distinct_posts_edited ud
    ON ud.user_id = u.id
ORDER BY up.total_posts_owned DESC NULLS LAST
LIMIT 100
