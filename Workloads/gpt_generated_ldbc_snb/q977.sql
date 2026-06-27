WITH forum_posts AS (
    SELECT f.id AS forum_id,
           COUNT(p.id) AS post_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT f.id AS forum_id,
           COUNT(c.id) AS comment_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_participants AS (
    SELECT up.forum_id,
           COUNT(DISTINCT up.person_id) AS participant_count
    FROM (
        SELECT f.id AS forum_id, p.creator_person_id AS person_id
        FROM forum f
        JOIN post p
            ON p.container_forum_id = f.id
        UNION
        SELECT f.id AS forum_id, c.creator_person_id AS person_id
        FROM forum f
        JOIN post p
            ON p.container_forum_id = f.id
        JOIN comment c
            ON c.parent_post_id = p.id
    ) up
    GROUP BY up.forum_id
),
forum_tag_usage AS (
    -- Tags applied to posts
    SELECT p.container_forum_id AS forum_id, pt.tag_id AS tag_id
    FROM post_has_tag_tag pt
    JOIN post p
        ON pt.post_id = p.id
    UNION ALL
    -- Tags applied to comments (via the post the comment belongs to)
    SELECT p.container_forum_id AS forum_id, ct.tag_id AS tag_id
    FROM comment_has_tag_tag ct
    JOIN comment c
        ON ct.comment_id = c.id
    JOIN post p
        ON c.parent_post_id = p.id
),
tag_counts AS (
    SELECT ft.forum_id,
           ft.tag_id,
           COUNT(*) AS usage_count
    FROM forum_tag_usage ft
    GROUP BY ft.forum_id, ft.tag_id
),
tag_ranked AS (
    SELECT tc.forum_id,
           tc.tag_id,
           tc.usage_count,
           ROW_NUMBER() OVER (PARTITION BY tc.forum_id ORDER BY tc.usage_count DESC) AS tag_rank
    FROM tag_counts tc
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(fp.post_count, 0)      AS post_count,
    COALESCE(fc.comment_count, 0)   AS comment_count,
    COALESCE(par.participant_count, 0) AS participant_count,
    t.name AS tag_name,
    tr.usage_count AS tag_usage,
    tr.tag_rank
FROM forum f
LEFT JOIN forum_posts fp
    ON fp.forum_id = f.id
LEFT JOIN forum_comments fc
    ON fc.forum_id = f.id
LEFT JOIN forum_participants par
    ON par.forum_id = f.id
LEFT JOIN tag_ranked tr
    ON tr.forum_id = f.id
   AND tr.tag_rank <= 3
LEFT JOIN tag t
    ON t.id = tr.tag_id
WHERE tr.tag_rank IS NOT NULL
ORDER BY f.id, tr.tag_rank
