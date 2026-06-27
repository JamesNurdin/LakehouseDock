WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id, f.title, f.creation_date
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenters
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(pl.person_id) AS like_count,
        COUNT(DISTINCT pl.person_id) AS distinct_likers
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY f.id
),
forum_members AS (
    SELECT
        f.id AS forum_id,
        COUNT(fhm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fhm ON fhm.forum_id = f.id
    GROUP BY f.id
)
SELECT
    fp.forum_id,
    fp.forum_title,
    fp.forum_creation_date,
    fp.post_count,
    fp.avg_post_length,
    fc.comment_count,
    fc.avg_comment_length,
    fc.distinct_commenters,
    fl.like_count,
    fl.distinct_likers,
    fm.member_count
FROM forum_posts fp
LEFT JOIN forum_comments fc ON fc.forum_id = fp.forum_id
LEFT JOIN forum_likes fl ON fl.forum_id = fp.forum_id
LEFT JOIN forum_members fm ON fm.forum_id = fp.forum_id
ORDER BY (
        fp.post_count +
        COALESCE(fc.comment_count, 0) +
        COALESCE(fl.like_count, 0)
    ) DESC
LIMIT 10
