WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        p.id AS post_id,
        p.length AS post_length
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
),
post_stats AS (
    SELECT
        forum_id,
        COUNT(DISTINCT post_id) AS post_count,
        AVG(post_length) AS avg_post_length
    FROM forum_posts
    GROUP BY forum_id
),
like_counts AS (
    SELECT
        fp.forum_id,
        COUNT(plp.person_id) AS like_count
    FROM forum_posts fp
    JOIN person_likes_post plp
        ON plp.post_id = fp.post_id
    GROUP BY fp.forum_id
),
comment_counts AS (
    SELECT
        fp.forum_id,
        COUNT(c.id) AS comment_count
    FROM forum_posts fp
    JOIN comment c
        ON c.parent_post_id = fp.post_id
    GROUP BY fp.forum_id
),
tag_counts AS (
    SELECT
        fp.forum_id,
        COUNT(DISTINCT pht.tag_id) AS tag_count
    FROM forum_posts fp
    JOIN post_has_tag_tag pht
        ON pht.post_id = fp.post_id
    GROUP BY fp.forum_id
),
moderator_info AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name
    FROM person p
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(lc.like_count, 0) AS like_count,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(tc.tag_count, 0) AS distinct_tag_count,
    ps.avg_post_length
FROM forum f
LEFT JOIN moderator_info mod
    ON f.moderator_person_id = mod.person_id
LEFT JOIN post_stats ps
    ON f.id = ps.forum_id
LEFT JOIN like_counts lc
    ON f.id = lc.forum_id
LEFT JOIN comment_counts cc
    ON f.id = cc.forum_id
LEFT JOIN tag_counts tc
    ON f.id = tc.forum_id
ORDER BY like_count DESC, post_count DESC
