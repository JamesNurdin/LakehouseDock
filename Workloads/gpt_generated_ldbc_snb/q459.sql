WITH forum_members AS (
    SELECT
        fhm.forum_id,
        COUNT(DISTINCT fhm.person_id) AS member_count
    FROM forum_has_member_person fhm
    GROUP BY fhm.forum_id
),
forum_posts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count
    FROM post p
    GROUP BY p.container_forum_id
),
forum_comments AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_like_count
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comment_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_like_count
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_post_creators AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_creator_count
    FROM post p
    GROUP BY p.container_forum_id
),
forum_comment_creators AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creator_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    fm.forum_id,
    fm.member_count,
    fp.post_count,
    fc.comment_count,
    fc.avg_comment_length,
    fpl.post_like_count,
    fcl.comment_like_count,
    fpc.distinct_post_creator_count,
    fcc.distinct_comment_creator_count
FROM forum_members fm
LEFT JOIN forum_posts fp ON fm.forum_id = fp.forum_id
LEFT JOIN forum_comments fc ON fm.forum_id = fc.forum_id
LEFT JOIN forum_post_likes fpl ON fm.forum_id = fpl.forum_id
LEFT JOIN forum_comment_likes fcl ON fm.forum_id = fcl.forum_id
LEFT JOIN forum_post_creators fpc ON fm.forum_id = fpc.forum_id
LEFT JOIN forum_comment_creators fcc ON fm.forum_id = fcc.forum_id
ORDER BY fpl.post_like_count DESC
LIMIT 10
