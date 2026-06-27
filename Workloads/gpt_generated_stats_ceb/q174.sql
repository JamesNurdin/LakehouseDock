WITH
    base_users AS (
        SELECT id AS user_id,
               reputation
        FROM users
    ),
    user_posts AS (
        SELECT owneruserid AS user_id,
               COUNT(*) AS total_posts,
               SUM(answercount) AS total_answers,
               SUM(score) AS total_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments_made AS (
        SELECT userid AS user_id,
               COUNT(*) AS total_comments_made
        FROM comments
        GROUP BY userid
    ),
    user_comments_received AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS total_comments_received
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_votes_cast AS (
        SELECT userid AS user_id,
               COUNT(*) AS total_votes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS total_votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT userid AS user_id,
               COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT lasteditoruserid AS user_id,
               COUNT(*) AS total_edits
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    user_posthistory AS (
        SELECT userid AS user_id,
               COUNT(*) AS total_posthistory_entries
        FROM posthistory
        GROUP BY userid
    )
SELECT
    bu.user_id,
    bu.reputation,
    COALESCE(up.total_posts, 0)                     AS total_posts,
    COALESCE(up.total_answers, 0)                  AS total_answers,
    COALESCE(up.total_post_score, 0)               AS total_post_score,
    COALESCE(ucm.total_comments_made, 0)           AS total_comments_made,
    COALESCE(ucr.total_comments_received, 0)      AS total_comments_received,
    COALESCE(uvc.total_votes_cast, 0)              AS total_votes_cast,
    COALESCE(uvr.total_votes_received, 0)          AS total_votes_received,
    COALESCE(ub.total_badges, 0)                   AS total_badges,
    COALESCE(ue.total_edits, 0)                    AS total_edits,
    COALESCE(uph.total_posthistory_entries, 0)    AS total_posthistory_entries,
    (
        COALESCE(up.total_posts, 0) +
        COALESCE(ucm.total_comments_made, 0) +
        COALESCE(ucr.total_comments_received, 0) +
        COALESCE(uvc.total_votes_cast, 0) +
        COALESCE(uvr.total_votes_received, 0) +
        COALESCE(ub.total_badges, 0) +
        COALESCE(ue.total_edits, 0) +
        COALESCE(uph.total_posthistory_entries, 0)
    )                                               AS total_engagement,
    ROW_NUMBER() OVER (
        ORDER BY (
            COALESCE(up.total_posts, 0) +
            COALESCE(ucm.total_comments_made, 0) +
            COALESCE(ucr.total_comments_received, 0) +
            COALESCE(uvc.total_votes_cast, 0) +
            COALESCE(uvr.total_votes_received, 0) +
            COALESCE(ub.total_badges, 0) +
            COALESCE(ue.total_edits, 0) +
            COALESCE(uph.total_posthistory_entries, 0)
        ) DESC
    )                                               AS engagement_rank
FROM base_users bu
LEFT JOIN user_posts up               ON bu.user_id = up.user_id
LEFT JOIN user_comments_made ucm      ON bu.user_id = ucm.user_id
LEFT JOIN user_comments_received ucr  ON bu.user_id = ucr.user_id
LEFT JOIN user_votes_cast uvc         ON bu.user_id = uvc.user_id
LEFT JOIN user_votes_received uvr     ON bu.user_id = uvr.user_id
LEFT JOIN user_badges ub              ON bu.user_id = ub.user_id
LEFT JOIN user_edits ue               ON bu.user_id = ue.user_id
LEFT JOIN user_posthistory uph        ON bu.user_id = uph.user_id
ORDER BY total_engagement DESC
LIMIT 100
