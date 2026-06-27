WITH forum_info AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date AS forum_creation_date,
        mod.gender AS moderator_gender
    FROM forum f
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
),
member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count,
        COUNT(DISTINCT p.location_country_id) AS distinct_country_count
    FROM post p
    GROUP BY p.container_forum_id
),
like_counts AS (
    SELECT
        plp.post_id,
        COUNT(*) AS like_count
    FROM person_likes_post plp
    GROUP BY plp.post_id
),
forum_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        SUM(lc.like_count) AS total_likes
    FROM post p
    LEFT JOIN like_counts lc
        ON p.id = lc.post_id
    GROUP BY p.container_forum_id
)
SELECT
    fi.title,
    fi.forum_creation_date,
    fi.moderator_gender,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(ps.distinct_creator_count, 0) AS distinct_creator_count,
    COALESCE(ps.distinct_country_count, 0) AS distinct_country_count,
    COALESCE(fl.total_likes, 0) AS total_likes
FROM forum_info fi
LEFT JOIN member_counts mc
    ON fi.forum_id = mc.forum_id
LEFT JOIN post_stats ps
    ON fi.forum_id = ps.forum_id
LEFT JOIN forum_likes fl
    ON fi.forum_id = fl.forum_id
ORDER BY total_likes DESC, post_count DESC
LIMIT 10
