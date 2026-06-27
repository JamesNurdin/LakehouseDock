/*
  Analytical query: forum activity and membership summary
  - For each forum we compute the number of posts, total post length, number of comments, average comment length.
  - We also compute the total number of members and the gender breakdown of members.
  - Results are ordered by the number of posts (most active forums first) and limited to the top 10.
*/
WITH post_comment_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id) AS post_count,
        COALESCE(SUM(p.length), 0) AS total_post_length,
        COUNT(DISTINCT c.id) AS comment_count,
        COALESCE(AVG(c.length), 0) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id, f.title
),
member_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT CASE WHEN per.gender = 'male' THEN per.id END) AS male_member_count,
        COUNT(DISTINCT CASE WHEN per.gender = 'female' THEN per.id END) AS female_member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
    LEFT JOIN person per ON per.id = fm.person_id
    GROUP BY f.id
)
SELECT
    pcs.forum_id,
    pcs.forum_title,
    pcs.post_count,
    pcs.total_post_length,
    pcs.comment_count,
    pcs.avg_comment_length,
    ms.member_count,
    ms.male_member_count,
    ms.female_member_count
FROM post_comment_stats pcs
LEFT JOIN member_stats ms ON ms.forum_id = pcs.forum_id
ORDER BY pcs.post_count DESC
LIMIT 10
