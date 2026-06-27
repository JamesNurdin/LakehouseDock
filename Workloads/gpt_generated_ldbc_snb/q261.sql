/*
  Analytical query for the LDBC SNB BI dataset (sf0003).
  It shows, per forum and gender (restricted to females), the number of distinct members,
  the total number of likes those members performed, how many members actually liked at
  least one post, and the average likes per member.
  The query respects the allowed join paths and uses only the selected tables.
*/
WITH forum_member_likes AS (
    SELECT
        f.forum_id,
        p.gender,
        f.person_id,
        pl.post_id
    FROM forum_has_member_person f
    JOIN person p
        ON f.person_id = p.id
    LEFT JOIN person_likes_post pl
        ON p.id = pl.person_id
    WHERE p.gender = 'female'
)
SELECT
    forum_id,
    gender,
    COUNT(DISTINCT person_id) AS member_count,
    COUNT(post_id) AS total_likes,
    COUNT(DISTINCT person_id) FILTER (WHERE post_id IS NOT NULL) AS members_who_liked,
    CAST(COUNT(post_id) AS double) / NULLIF(COUNT(DISTINCT person_id), 0) AS avg_likes_per_member
FROM forum_member_likes
GROUP BY forum_id, gender
ORDER BY total_likes DESC
LIMIT 10
