WITH
    user_posts AS (
        SELECT owneruserid AS user_id,
               COUNT(*) AS post_count,
               AVG(score) AS avg_post_score,
               AVG(viewcount) AS avg_viewcount,
               SUM(answercount) AS total_answers,
               SUM(commentcount) AS total_comments_on_posts
        FROM posts
        GROUP BY owneruserid
    ),
    user_edits AS (
        SELECT lasteditoruserid AS user_id,
               COUNT(*) AS edit_count
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    user_comments AS (
        SELECT userid AS user_id,
               COUNT(*) AS comment_count,
               AVG(score) AS avg_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT userid AS user_id,
               COUNT(*) AS vote_cast_count,
               SUM(COALESCE(bountyamount, 0)) AS total_bounty_awarded
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT userid AS user_id,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posthistory AS (
        SELECT userid AS user_id,
               COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    user_tags AS (
        SELECT p.owneruserid AS user_id,
               COUNT(DISTINCT t.id) AS tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT p.owneruserid AS user_id,
               COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0)               AS post_count,
       COALESCE(up.avg_post_score, 0)           AS avg_post_score,
       COALESCE(up.avg_viewcount, 0)            AS avg_viewcount,
       COALESCE(up.total_answers, 0)            AS total_answers,
       COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
       COALESCE(ue.edit_count, 0)               AS edit_count,
       COALESCE(uc.comment_count, 0)            AS comment_count,
       COALESCE(uc.avg_comment_score, 0)        AS avg_comment_score,
       COALESCE(uv.vote_cast_count, 0)          AS vote_cast_count,
       COALESCE(uv.total_bounty_awarded, 0)     AS total_bounty_awarded,
       COALESCE(ub.badge_count, 0)              AS badge_count,
       COALESCE(uph.posthistory_count, 0)       AS posthistory_count,
       COALESCE(ut.tag_count, 0)                AS tag_count,
       COALESCE(ulp.postlink_count, 0)          AS postlink_count
FROM users u
LEFT JOIN user_posts       up   ON up.user_id   = u.id
LEFT JOIN user_edits       ue   ON ue.user_id   = u.id
LEFT JOIN user_comments    uc   ON uc.user_id   = u.id
LEFT JOIN user_votes       uv   ON uv.user_id   = u.id
LEFT JOIN user_badges      ub   ON ub.user_id   = u.id
LEFT JOIN user_posthistory uph  ON uph.user_id  = u.id
LEFT JOIN user_tags        ut   ON ut.user_id   = u.id
LEFT JOIN user_postlinks   ulp  ON ulp.user_id  = u.id
ORDER BY post_count DESC
LIMIT 10
