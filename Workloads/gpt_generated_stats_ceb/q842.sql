WITH base_posts AS (
    SELECT t.id AS tag_id,
           p.id AS post_id,
           p.owneruserid,
           p.lasteditoruserid,
           p.score AS post_score,
           p.viewcount AS post_viewcount,
           p.answercount,
           p.commentcount,
           p.favoritecount
    FROM tags t
    JOIN posts p ON p.id = t.excerptpostid
),
comment_agg AS (
    SELECT c.postid AS post_id,
           COUNT(c.id) AS comment_count,
           SUM(c.score) AS comment_score_sum,
           COUNT(DISTINCT c.userid) AS distinct_commenters
    FROM comments c
    GROUP BY c.postid
),
posthistory_agg AS (
    SELECT ph.posthistorytypeid AS post_id,
           COUNT(ph.id) AS posthistory_count,
           COUNT(DISTINCT ph.userid) AS distinct_history_users
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
)
SELECT bp.tag_id,
       bp.post_id,
       bp.post_score,
       bp.post_viewcount,
       owner_user.reputation AS owner_reputation,
       editor_user.reputation AS editor_reputation,
       COALESCE(ca.comment_count, 0) AS comment_count,
       COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
       COALESCE(ca.distinct_commenters, 0) AS distinct_commenters,
       COALESCE(pha.posthistory_count, 0) AS posthistory_count,
       COALESCE(pha.distinct_history_users, 0) AS distinct_history_users
FROM base_posts bp
LEFT JOIN users owner_user ON owner_user.id = bp.owneruserid
LEFT JOIN users editor_user ON editor_user.id = bp.lasteditoruserid
LEFT JOIN comment_agg ca ON ca.post_id = bp.post_id
LEFT JOIN posthistory_agg pha ON pha.post_id = bp.post_id
ORDER BY bp.post_viewcount DESC
LIMIT 100
