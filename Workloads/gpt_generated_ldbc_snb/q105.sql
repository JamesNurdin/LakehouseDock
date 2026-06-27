WITH tagged_comments AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        c.id AS comment_id,
        c.length AS comment_length,
        p.id AS person_id,
        fm.forum_id AS forum_id
    FROM person p
    JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
    JOIN tag t
        ON t.id = pit.tag_id
    JOIN comment c
        ON c.creator_person_id = p.id
    JOIN forum_has_member_person fm
        ON fm.person_id = p.id
    WHERE c.parent_post_id IS NOT NULL
)
SELECT
    tag_id,
    tag_name,
    COUNT(DISTINCT comment_id) AS comment_count,
    SUM(comment_length) AS total_comment_length,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT person_id) AS distinct_authors,
    COUNT(DISTINCT forum_id) AS distinct_forums
FROM tagged_comments
GROUP BY tag_id, tag_name
ORDER BY total_comment_length DESC
LIMIT 10
