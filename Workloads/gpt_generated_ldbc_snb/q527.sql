WITH member_counts AS (
    SELECT fmp.forum_id,
           COUNT(DISTINCT fmp.person_id) AS member_count
    FROM forum_has_member_person AS fmp
    GROUP BY fmp.forum_id
),

tag_counts AS (
    SELECT ft.forum_id,
           COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum_has_tag_tag AS ft
    GROUP BY ft.forum_id
),

tag_names AS (
    SELECT ft.forum_id,
           array_agg(DISTINCT t.name) AS tag_names
    FROM forum_has_tag_tag AS ft
    JOIN tag AS t
        ON ft.tag_id = t.id
    GROUP BY ft.forum_id
),

post_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           SUM(p.length) AS total_post_length,
           AVG(p.length) AS avg_post_length
    FROM post AS p
    GROUP BY p.container_forum_id
)
SELECT f.id AS forum_id,
       f.title,
       mod_person.first_name AS moderator_first_name,
       mod_person.last_name AS moderator_last_name,
       COALESCE(mc.member_count, 0) AS member_count,
       COALESCE(tc.tag_count, 0) AS tag_count,
       COALESCE(tn.tag_names, CAST(ARRAY[] AS array(varchar))) AS tag_names,
       COALESCE(ps.post_count, 0) AS post_count,
       COALESCE(ps.total_post_length, 0) AS total_post_length,
       COALESCE(ps.avg_post_length, 0) AS avg_post_length
FROM forum AS f
LEFT JOIN member_counts AS mc
    ON mc.forum_id = f.id
LEFT JOIN tag_counts AS tc
    ON tc.forum_id = f.id
LEFT JOIN tag_names AS tn
    ON tn.forum_id = f.id
LEFT JOIN post_stats AS ps
    ON ps.forum_id = f.id
LEFT JOIN person AS mod_person
    ON f.moderator_person_id = mod_person.id
ORDER BY f.id
