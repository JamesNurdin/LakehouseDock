-- Top 10 forums by total likes on posts, with member, tag, post and like statistics
WITH member_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fmmp
      ON fmmp.forum_id = f.id
    JOIN person p
      ON p.id = fmmp.person_id
    GROUP BY f.id
),
tag_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT t.id) AS tag_count
    FROM forum f
    JOIN forum_has_tag_tag fhtt
      ON fhtt.forum_id = f.id
    JOIN tag t
      ON t.id = fhtt.tag_id
    GROUP BY f.id
),
post_stats AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT po.id) AS post_count,
           AVG(po.length) AS avg_post_length
    FROM forum f
    JOIN post po
      ON po.container_forum_id = f.id
    GROUP BY f.id
),
like_counts AS (
    SELECT f.id AS forum_id,
           COUNT(plp.person_id) AS total_likes
    FROM forum f
    JOIN post po
      ON po.container_forum_id = f.id
    JOIN person_likes_post plp
      ON plp.post_id = po.id
    GROUP BY f.id
)
SELECT f.id,
       f.title,
       COALESCE(mc.member_count, 0) AS member_count,
       COALESCE(tc.tag_count, 0) AS tag_count,
       COALESCE(ps.post_count, 0) AS post_count,
       ps.avg_post_length,
       COALESCE(lc.total_likes, 0) AS total_likes,
       CASE
           WHEN COALESCE(ps.post_count, 0) > 0
           THEN CAST(lc.total_likes AS double) / ps.post_count
           ELSE 0
       END AS avg_likes_per_post
FROM forum f
LEFT JOIN member_counts mc   ON mc.forum_id = f.id
LEFT JOIN tag_counts    tc   ON tc.forum_id = f.id
LEFT JOIN post_stats    ps   ON ps.forum_id = f.id
LEFT JOIN like_counts   lc   ON lc.forum_id = f.id
ORDER BY total_likes DESC
LIMIT 10
