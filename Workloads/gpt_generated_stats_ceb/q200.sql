WITH
    user_posts AS (
        SELECT owneruserid AS userid,
               count(*) AS post_count,
               sum(score) AS total_score,
               sum(viewcount) AS total_views
        FROM posts
        GROUP BY owneruserid
    ),
    user_answers AS (
        SELECT owneruserid AS userid,
               count(*) AS answer_count
        FROM posts
        WHERE posttypeid = 2
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT userid,
               count(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT userid,
               count(*) AS vote_count
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT userid,
               count(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT lasteditoruserid AS userid,
               count(*) AS edit_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    user_posthistory AS (
        SELECT userid,
               count(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    user_tags AS (
        SELECT p.owneruserid AS userid,
               count(distinct t.id) AS tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT p.owneruserid AS userid,
               count(*) AS link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT u.id AS user_id,
       u.reputation,
       coalesce(up.post_count, 0) AS post_count,
       coalesce(ua.answer_count, 0) AS answer_count,
       coalesce(up.total_score, 0) AS total_post_score,
       coalesce(up.total_views, 0) AS total_post_views,
       coalesce(uc.comment_count, 0) AS comment_count,
       coalesce(uv.vote_count, 0) AS vote_count,
       coalesce(ub.badge_count, 0) AS badge_count,
       coalesce(ue.edit_count, 0) AS edit_count,
       coalesce(uph.posthistory_count, 0) AS posthistory_count,
       coalesce(ut.tag_count, 0) AS tag_count,
       coalesce(upl.link_count, 0) AS link_count,
       -- derived metrics
       up.total_score / nullif(up.post_count, 0) AS average_score,
       ua.answer_count / nullif(up.post_count, 0) AS answer_ratio
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_answers ua ON ua.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_tags ut ON ut.userid = u.id
LEFT JOIN user_postlinks upl ON upl.userid = u.id
ORDER BY post_count DESC, answer_count DESC
LIMIT 100
