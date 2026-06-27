WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
),
members_agg AS (
    SELECT
        fmmp.forum_id,
        COUNT(DISTINCT fmmp.person_id) AS member_count
    FROM forum_has_member_person fmmp
    GROUP BY fmmp.forum_id
),
tags_agg AS (
    SELECT
        fhtt.forum_id,
        COUNT(DISTINCT fhtt.tag_id) AS tag_count
    FROM forum_has_tag_tag fhtt
    GROUP BY fhtt.forum_id
),
posts_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comments_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_likes_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_like_count,
        COUNT(DISTINCT plp.person_id) AS distinct_post_likers
    FROM person_likes_post plp
    JOIN post p
        ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_like_count,
        COUNT(DISTINCT plc.person_id) AS distinct_comment_likers
    FROM person_likes_comment plc
    JOIN comment c
        ON plc.comment_id = c.id
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
distinct_likers_agg AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS distinct_likers
    FROM (
        SELECT
            p.container_forum_id AS forum_id,
            plp.person_id AS person_id
        FROM person_likes_post plp
        JOIN post p
            ON plp.post_id = p.id
        UNION ALL
        SELECT
            p.container_forum_id AS forum_id,
            plc.person_id AS person_id
        FROM person_likes_comment plc
        JOIN comment c
            ON plc.comment_id = c.id
        JOIN post p
            ON c.parent_post_id = p.id
    ) u
    GROUP BY forum_id
)
SELECT
    fb.forum_id,
    fb.title,
    fb.moderator_first_name,
    fb.moderator_last_name,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pl.post_like_count, 0) AS post_like_count,
    COALESCE(pl.distinct_post_likers, 0) AS distinct_post_likers,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count,
    COALESCE(cl.distinct_comment_likers, 0) AS distinct_comment_likers,
    COALESCE(dl.distinct_likers, 0) AS distinct_likers
FROM forum_base fb
LEFT JOIN members_agg m
    ON m.forum_id = fb.forum_id
LEFT JOIN tags_agg t
    ON t.forum_id = fb.forum_id
LEFT JOIN posts_agg p
    ON p.forum_id = fb.forum_id
LEFT JOIN comments_agg c
    ON c.forum_id = fb.forum_id
LEFT JOIN post_likes_agg pl
    ON pl.forum_id = fb.forum_id
LEFT JOIN comment_likes_agg cl
    ON cl.forum_id = fb.forum_id
LEFT JOIN distinct_likers_agg dl
    ON dl.forum_id = fb.forum_id
ORDER BY member_count DESC
LIMIT 20
