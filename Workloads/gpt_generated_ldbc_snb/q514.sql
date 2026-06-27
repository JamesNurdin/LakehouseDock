WITH member_counts AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),

tag_counts AS (
    SELECT ft.forum_id,
           COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),

post_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),

likes_per_forum AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(plp.person_id) AS total_likes
    FROM post p
    JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),

creator_counts AS (
    SELECT p.container_forum_id AS forum_id,
           p.creator_person_id,
           COUNT(*) AS created_posts
    FROM post p
    GROUP BY p.container_forum_id, p.creator_person_id
),

top_contributors AS (
    SELECT c.forum_id,
           c.creator_person_id,
           c.created_posts
    FROM (
        SELECT c.*,
               ROW_NUMBER() OVER (PARTITION BY c.forum_id ORDER BY c.created_posts DESC) AS rn
        FROM creator_counts c
    ) c
    WHERE c.rn = 1
)
SELECT f.id AS forum_id,
       f.title,
       mod.first_name || ' ' || mod.last_name AS moderator_name,
       mc.member_count,
       tc.tag_count,
       ps.post_count,
       ps.avg_post_length,
       lp.total_likes,
       (lp.total_likes / NULLIF(ps.post_count, 0)) AS avg_likes_per_post,
       (mc.member_count / NULLIF(ps.post_count, 0)) AS members_per_post,
       tc2.creator_person_id AS top_contributor_id,
       top.first_name || ' ' || top.last_name AS top_contributor_name,
       tc2.created_posts AS top_contributor_post_count
FROM forum f
LEFT JOIN member_counts mc ON mc.forum_id = f.id
LEFT JOIN tag_counts tc ON tc.forum_id = f.id
LEFT JOIN post_stats ps ON ps.forum_id = f.id
LEFT JOIN likes_per_forum lp ON lp.forum_id = f.id
LEFT JOIN top_contributors tc2 ON tc2.forum_id = f.id
LEFT JOIN person mod ON f.moderator_person_id = mod.id
LEFT JOIN person top ON tc2.creator_person_id = top.id
ORDER BY f.id
