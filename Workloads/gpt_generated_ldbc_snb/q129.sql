/*
  Analytical query: For each forum, list the top 3 tags used in its posts (by number of posts).
  For each tag we also show how many forum members have expressed interest in that tag.
  The query respects all join rules and uses only the selected tables.
*/
WITH forum_tag_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT po.id) AS post_count,
        COUNT(DISTINCT CASE WHEN pit.person_id IS NOT NULL THEN p.id END) AS member_interest_count
    FROM forum f
    JOIN post po
        ON po.container_forum_id = f.id
    JOIN post_has_tag_tag pt
        ON pt.post_id = po.id
    JOIN tag t
        ON t.id = pt.tag_id
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN person p
        ON p.id = fm.person_id
    LEFT JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
        AND pit.tag_id = t.id
    GROUP BY f.id, f.title, t.id, t.name
)
SELECT
    forum_id,
    forum_title,
    tag_name,
    post_count,
    member_interest_count
FROM (
    SELECT
        forum_id,
        forum_title,
        tag_name,
        post_count,
        member_interest_count,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY post_count DESC) AS rn
    FROM forum_tag_stats
) sub
WHERE rn <= 3
ORDER BY forum_id, rn
