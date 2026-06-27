WITH user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(AVG(p.answercount), 0) AS avg_answer_count,
           COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS vote_cast_count,
           COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cast,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_post_votes AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS total_votes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_received,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_links AS (
    SELECT u.id AS user_id,
           COUNT(DISTINCT pl.id) AS outgoing_link_count,
           COUNT(DISTINCT pl_rel.id) AS incoming_link_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    LEFT JOIN postlinks pl_rel
        ON pl_rel.relatedpostid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0)               AS post_count,
       COALESCE(up.total_post_score, 0)          AS total_post_score,
       COALESCE(up.avg_answer_count, 0)          AS avg_answer_count,
       COALESCE(up.total_favorite_count, 0)      AS total_favorite_count,
       COALESCE(uc.comment_count, 0)             AS comment_count,
       COALESCE(uc.total_comment_score, 0)       AS total_comment_score,
       COALESCE(uv.vote_cast_count, 0)           AS vote_cast_count,
       COALESCE(uv.upvote_cast, 0)               AS upvote_cast,
       COALESCE(uv.downvote_cast, 0)             AS downvote_cast,
       COALESCE(upv.total_votes_received, 0)    AS total_votes_received,
       COALESCE(upv.upvotes_received, 0)         AS upvotes_received,
       COALESCE(upv.downvotes_received, 0)       AS downvotes_received,
       COALESCE(ub.badge_count, 0)               AS badge_count,
       COALESCE(ue.edit_count, 0)                AS edit_count,
       COALESCE(ut.distinct_tag_count, 0)        AS distinct_tag_count,
       COALESCE(ul.outgoing_link_count, 0)       AS outgoing_link_count,
       COALESCE(ul.incoming_link_count, 0)       AS incoming_link_count
FROM users u
LEFT JOIN user_posts        up  ON up.user_id = u.id
LEFT JOIN user_comments     uc  ON uc.user_id = u.id
LEFT JOIN user_votes        uv  ON uv.user_id = u.id
LEFT JOIN user_post_votes   upv ON upv.user_id = u.id
LEFT JOIN user_badges       ub  ON ub.user_id = u.id
LEFT JOIN user_edits        ue  ON ue.user_id = u.id
LEFT JOIN user_tags         ut  ON ut.user_id = u.id
LEFT JOIN user_links        ul  ON ul.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 10
