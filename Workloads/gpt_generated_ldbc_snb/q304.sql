WITH forum_posts AS (
    SELECT f.id AS forum_id,
           f.title,
           p.id AS post_id
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
),
post_counts AS (
    SELECT fp.forum_id,
           COUNT(DISTINCT fp.post_id) AS post_count
    FROM forum_posts fp
    GROUP BY fp.forum_id
),
post_likes AS (
    SELECT fp.forum_id,
           COUNT(plp.person_id) AS likes_count
    FROM forum_posts fp
    JOIN person_likes_post plp ON plp.post_id = fp.post_id
    GROUP BY fp.forum_id
),
member_counts AS (
    SELECT fhm.forum_id,
           COUNT(DISTINCT fhm.person_id) AS member_count
    FROM forum_has_member_person fhm
    GROUP BY fhm.forum_id
),
member_interests AS (
    SELECT fhm.forum_id,
           pit.tag_id,
           COUNT(DISTINCT pit.person_id) AS tag_user_count
    FROM forum_has_member_person fhm
    JOIN person_has_interest_tag pit ON pit.person_id = fhm.person_id
    GROUP BY fhm.forum_id, pit.tag_id
),
top_tag_per_forum AS (
    SELECT mi.forum_id,
           mi.tag_id,
           mi.tag_user_count,
           ROW_NUMBER() OVER (PARTITION BY mi.forum_id ORDER BY mi.tag_user_count DESC, mi.tag_id) AS rn
    FROM member_interests mi
)
SELECT f.id AS forum_id,
       f.title,
       pc.post_count,
       COALESCE(pl.likes_count, 0) AS total_likes,
       CASE WHEN pc.post_count > 0 THEN COALESCE(pl.likes_count, 0) * 1.0 / pc.post_count ELSE 0 END AS avg_likes_per_post,
       mc.member_count,
       tt.tag_id AS top_tag_id,
       tt.tag_user_count AS top_tag_user_count
FROM forum f
LEFT JOIN post_counts pc ON pc.forum_id = f.id
LEFT JOIN post_likes pl ON pl.forum_id = f.id
LEFT JOIN member_counts mc ON mc.forum_id = f.id
LEFT JOIN top_tag_per_forum tt ON tt.forum_id = f.id AND tt.rn = 1
ORDER BY total_likes DESC
LIMIT 20
