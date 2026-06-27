WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           mod.first_name AS moderator_first_name,
           mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person mod ON f.moderator_person_id = mod.id
),
post_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
like_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(plp.person_id) AS total_likes
    FROM post p
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
member_agg AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_tag_agg AS (
    SELECT ft.forum_id,
           COUNT(DISTINCT ft.tag_id) AS forum_tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),
post_tag_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pht.tag_id) AS post_tag_count
    FROM post p
    LEFT JOIN post_has_tag_tag pht ON pht.post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    fb.forum_id,
    fb.forum_title,
    fb.moderator_first_name,
    fb.moderator_last_name,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(pa.avg_post_length, 0) AS avg_post_length,
    COALESCE(la.total_likes, 0) AS total_likes,
    COALESCE(ma.member_count, 0) AS member_count,
    COALESCE(fta.forum_tag_count, 0) AS forum_tag_count,
    COALESCE(pta.post_tag_count, 0) AS post_tag_count,
    CAST(COALESCE(la.total_likes, 0) AS double) /
        NULLIF(COALESCE(pa.post_count, 0), 0) AS avg_likes_per_post
FROM forum_base fb
LEFT JOIN post_agg pa ON pa.forum_id = fb.forum_id
LEFT JOIN like_agg la ON la.forum_id = fb.forum_id
LEFT JOIN member_agg ma ON ma.forum_id = fb.forum_id
LEFT JOIN forum_tag_agg fta ON fta.forum_id = fb.forum_id
LEFT JOIN post_tag_agg pta ON pta.forum_id = fb.forum_id
ORDER BY post_count DESC
LIMIT 10
