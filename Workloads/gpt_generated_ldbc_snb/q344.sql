/*
  Analytical query: forum‑level statistics broken down by tag,
  including post counts, average length, likes, comments,
  distinct authors/commenters and how many posts were created by
  persons that have a work record (person_work_at_company).
*/
WITH post_details AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        p.id AS post_id,
        p.length AS post_length,
        p.creator_person_id AS post_creator_id,
        CASE WHEN pwc.person_id IS NOT NULL THEN 1 ELSE 0 END AS has_employment
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    JOIN person per
        ON p.creator_person_id = per.id
    LEFT JOIN person_work_at_company pwc
        ON pwc.person_id = per.id
)
SELECT
    pd.forum_id,
    pd.forum_title,
    t.tag_id,
    COUNT(DISTINCT pd.post_id)                     AS num_posts,
    AVG(pd.post_length)                            AS avg_post_length,
    SUM(pd.has_employment)                         AS posts_by_employees,
    COUNT(DISTINCT plp.person_id)                  AS num_likes,
    COUNT(DISTINCT c.id)                           AS num_comments,
    COUNT(DISTINCT pd.post_creator_id)             AS num_authors,
    COUNT(DISTINCT c.creator_person_id)            AS num_commenters
FROM post_details pd
LEFT JOIN post_has_tag_tag t
    ON t.post_id = pd.post_id
LEFT JOIN person_likes_post plp
    ON plp.post_id = pd.post_id
LEFT JOIN comment c
    ON c.parent_post_id = pd.post_id
GROUP BY pd.forum_id, pd.forum_title, t.tag_id
ORDER BY num_likes DESC
LIMIT 20
