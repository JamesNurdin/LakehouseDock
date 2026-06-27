WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        p.id AS post_id,
        p.creator_person_id AS post_creator_id
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
),
post_agg AS (
    SELECT
        forum_id,
        forum_title,
        COUNT(DISTINCT post_id) AS post_count
    FROM forum_posts
    GROUP BY forum_id, forum_title
),
forum_comments AS (
    SELECT
        fp.forum_id,
        fp.forum_title,
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id AS comment_creator_id
    FROM forum_posts fp
    JOIN comment c
        ON c.parent_post_id = fp.post_id
),
comment_agg AS (
    SELECT
        forum_id,
        forum_title,
        COUNT(DISTINCT comment_id) AS comment_count,
        AVG(comment_length) AS avg_comment_length
    FROM forum_comments
    GROUP BY forum_id, forum_title
),
forum_comment_tags AS (
    SELECT
        fc.forum_id,
        ct.tag_id AS tag_id
    FROM forum_comments fc
    JOIN comment_has_tag_tag ct
        ON ct.comment_id = fc.comment_id
),
tag_agg AS (
    SELECT
        forum_id,
        COUNT(DISTINCT tag_id) AS distinct_tag_count
    FROM forum_comment_tags
    GROUP BY forum_id
),
forum_participants AS (
    SELECT forum_id, post_creator_id AS person_id
    FROM forum_posts
    UNION
    SELECT forum_id, comment_creator_id AS person_id
    FROM forum_comments
),
participant_agg AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS participant_count
    FROM forum_participants
    GROUP BY forum_id
)
SELECT
    pa.forum_id,
    pa.forum_title,
    pa.post_count,
    ca.comment_count,
    ca.avg_comment_length,
    ta.distinct_tag_count,
    pa2.participant_count
FROM post_agg pa
LEFT JOIN comment_agg ca
    ON ca.forum_id = pa.forum_id
LEFT JOIN tag_agg ta
    ON ta.forum_id = pa.forum_id
LEFT JOIN participant_agg pa2
    ON pa2.forum_id = pa.forum_id
ORDER BY pa.post_count DESC
LIMIT 10
