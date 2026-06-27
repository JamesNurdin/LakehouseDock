WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS total_posts,
           SUM(p.answercount) AS total_answers,
           SUM(p.commentcount) AS total_comments_on_posts,
           SUM(p.score) AS total_post_score,
           SUM(p.viewcount) AS total_viewcount
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS total_comments_made,
           SUM(c.score) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS total_votes_cast,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
           SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS total_badges
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT u.id AS user_id,
           COUNT(pl.id) AS total_postlinks_created
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS total_posthistory_entries
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(uc.total_comments_made, 0) AS total_comments_made,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uv.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(uv.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uv.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(ulp.total_postlinks_created, 0) AS total_postlinks_created,
    COALESCE(uph.total_posthistory_entries, 0) AS total_posthistory_entries,
    -- Example derived metric: average post score (0 if no posts)
    CASE WHEN COALESCE(up.total_posts, 0) = 0 THEN 0
         ELSE COALESCE(up.total_post_score, 0) * 1.0 / COALESCE(up.total_posts, 1)
    END AS avg_post_score
FROM users u
LEFT JOIN user_posts up      ON up.user_id = u.id
LEFT JOIN user_comments uc   ON uc.user_id = u.id
LEFT JOIN user_votes uv      ON uv.user_id = u.id
LEFT JOIN user_badges ub     ON ub.user_id = u.id
LEFT JOIN user_postlinks ulp ON ulp.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
