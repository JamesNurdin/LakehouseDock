/* Analytical query: forum metrics with moderator info, member count,
   post statistics, likes, and the most common interest tag among members */
WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date AS forum_creation_date,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name
    FROM forum AS f
    LEFT JOIN person AS mod
        ON f.moderator_person_id = mod.id
),
member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person AS fm
    GROUP BY fm.forum_id
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post AS p
    GROUP BY p.container_forum_id
),
like_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plp.person_id) AS total_likes,
        COUNT(DISTINCT plp.person_id) AS distinct_likers
    FROM post AS p
    LEFT JOIN person_likes_post AS plp
        ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
member_tag_counts AS (
    SELECT
        fm.forum_id,
        pt.tag_id,
        COUNT(*) AS tag_cnt
    FROM forum_has_member_person AS fm
    JOIN person AS per
        ON fm.person_id = per.id
    JOIN person_has_interest_tag AS pt
        ON pt.person_id = per.id
    GROUP BY fm.forum_id, pt.tag_id
),
top_tag_per_forum AS (
    SELECT
        forum_id,
        tag_id,
        tag_cnt,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_cnt DESC) AS rn
    FROM member_tag_counts
)
SELECT
    fb.forum_id,
    fb.title,
    fb.forum_creation_date,
    fb.moderator_first_name,
    fb.moderator_last_name,
    COALESCE(mc.member_count, 0)            AS member_count,
    COALESCE(ps.post_count, 0)              AS post_count,
    COALESCE(ps.avg_post_length, 0)         AS avg_post_length,
    COALESCE(ls.total_likes, 0)             AS total_likes,
    COALESCE(ls.distinct_likers, 0)         AS distinct_likers,
    tt.tag_id                               AS top_member_tag_id,
    tt.tag_cnt                              AS top_member_tag_count
FROM forum_base AS fb
LEFT JOIN member_counts AS mc
    ON mc.forum_id = fb.forum_id
LEFT JOIN post_stats AS ps
    ON ps.forum_id = fb.forum_id
LEFT JOIN like_stats AS ls
    ON ls.forum_id = fb.forum_id
LEFT JOIN (
    SELECT forum_id, tag_id, tag_cnt
    FROM top_tag_per_forum
    WHERE rn = 1
) AS tt
    ON tt.forum_id = fb.forum_id
ORDER BY post_count DESC
LIMIT 10
