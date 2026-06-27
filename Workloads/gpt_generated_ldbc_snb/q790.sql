/*
   Top 5 most active forum members by number of comments they have authored in each forum.
   For each forum we count the comments created by members, sum the comment lengths,
   rank members by comment count (and total length as a tie‑breaker) and return the top five.
*/
WITH forum_member_comments AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        p.id AS person_id,
        p.first_name,
        p.last_name,
        c.id AS comment_id,
        c.length AS comment_length
    FROM forum AS f
    JOIN forum_has_member_person AS fm
        ON fm.forum_id = f.id
    JOIN person AS p
        ON fm.person_id = p.id
    JOIN comment AS c
        ON c.creator_person_id = p.id
    JOIN post AS po
        ON c.parent_post_id = po.id
    WHERE po.container_forum_id = f.id
),
member_comment_agg AS (
    SELECT
        forum_id,
        forum_title,
        person_id,
        first_name,
        last_name,
        COUNT(comment_id) AS comment_count,
        SUM(comment_length) AS total_comment_length
    FROM forum_member_comments
    GROUP BY forum_id, forum_title, person_id, first_name, last_name
),
member_comment_rank AS (
    SELECT
        forum_id,
        forum_title,
        person_id,
        first_name,
        last_name,
        comment_count,
        total_comment_length,
        ROW_NUMBER() OVER (
            PARTITION BY forum_id
            ORDER BY comment_count DESC, total_comment_length DESC
        ) AS rn
    FROM member_comment_agg
)
SELECT
    forum_id,
    forum_title,
    person_id,
    first_name,
    last_name,
    comment_count,
    total_comment_length
FROM member_comment_rank
WHERE rn <= 5
ORDER BY forum_id, comment_count DESC
