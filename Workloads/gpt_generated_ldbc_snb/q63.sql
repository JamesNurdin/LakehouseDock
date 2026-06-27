/*
  Analytical query: For each organisation (company) that employs comment authors,
  count the total number of comments they posted, the total number of replies
  those comments received, the average comment length, the average number of
  replies per comment, and the number of distinct commenters.
  The query follows the allowed join rules and uses only the selected tables.
*/
SELECT
    o.id   AS org_id,
    o.name AS org_name,
    o.type AS org_type,
    COUNT(c.id)                                 AS total_comments,
    COUNT(r.id)                                 AS total_replies,
    AVG(c.length)                               AS avg_comment_length,
    CASE WHEN COUNT(c.id) = 0 THEN 0.0
         ELSE CAST(COUNT(r.id) AS double) / COUNT(c.id)
    END                                         AS avg_replies_per_comment,
    COUNT(DISTINCT p.id)                        AS distinct_commenters
FROM comment c
-- self‑join to capture replies to a comment
LEFT JOIN comment r
       ON r.parent_comment_id = c.id
JOIN person p
       ON c.creator_person_id = p.id
JOIN person_work_at_company pwc
       ON p.id = pwc.person_id
JOIN organisation o
       ON pwc.company_id = o.id
GROUP BY o.id, o.name, o.type
ORDER BY total_comments DESC
LIMIT 10
