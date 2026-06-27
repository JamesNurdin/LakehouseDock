WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_likes_post AS (
    SELECT
        f.id AS forum_id,
        COUNT(pl.person_id) AS total_likes_post
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY f.id
),
forum_likes_comment AS (
    SELECT
        f.id AS forum_id,
        COUNT(cl.person_id) AS total_likes_comment
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    GROUP BY f.id
),
forum_participants AS (
    SELECT f.id AS forum_id, fmp.person_id
    FROM forum_has_member_person fmp
    JOIN forum f ON fmp.forum_id = f.id
    UNION
    SELECT f.id AS forum_id, f.moderator_person_id AS person_id
    FROM forum f
    UNION
    SELECT f.id AS forum_id, p.creator_person_id AS person_id
    FROM post p
    JOIN forum f ON p.container_forum_id = f.id
    UNION
    SELECT f.id AS forum_id, c.creator_person_id AS person_id
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
    UNION
    SELECT f.id AS forum_id, pl.person_id
    FROM person_likes_post pl
    JOIN post p ON pl.post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
    UNION
    SELECT f.id AS forum_id, cl.person_id
    FROM person_likes_comment cl
    JOIN comment c ON cl.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
),
forum_distinct_participants AS (
    SELECT forum_id, COUNT(DISTINCT person_id) AS distinct_participants
    FROM forum_participants
    GROUP BY forum_id
),
forum_post_tags AS (
    SELECT f.id AS forum_id, COUNT(DISTINCT pht.tag_id) AS distinct_post_tags
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN post_has_tag_tag pht ON pht.post_id = p.id
    GROUP BY f.id
),
forum_comment_tags AS (
    SELECT f.id AS forum_id, COUNT(DISTINCT cht.tag_id) AS distinct_comment_tags
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    GROUP BY f.id
)
SELECT
    f.id AS forum_id,
    f.title,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(flpost.total_likes_post, 0) AS total_likes_post,
    COALESCE(flcomment.total_likes_comment, 0) AS total_likes_comment,
    COALESCE(fdp.distinct_participants, 0) AS distinct_participants,
    COALESCE(fpt.distinct_post_tags, 0) AS distinct_post_tags,
    COALESCE(fct.distinct_comment_tags, 0) AS distinct_comment_tags
FROM forum f
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_likes_post flpost ON flpost.forum_id = f.id
LEFT JOIN forum_likes_comment flcomment ON flcomment.forum_id = f.id
LEFT JOIN forum_distinct_participants fdp ON fdp.forum_id = f.id
LEFT JOIN forum_post_tags fpt ON fpt.forum_id = f.id
LEFT JOIN forum_comment_tags fct ON fct.forum_id = f.id
ORDER BY post_count DESC, comment_count DESC
LIMIT 10
