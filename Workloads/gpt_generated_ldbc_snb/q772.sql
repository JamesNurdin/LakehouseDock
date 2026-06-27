/*
  Analytical query: forum‑level activity summary
  - Number of posts and average post length
  - Number of comments and average comment length
  - Number of forum members
  - Likes on posts and comments
  - Distinct tags used in posts and attached to the forum
  The result is ordered by the most active forums (by post count) and limited to the top 10.
*/
WITH post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
member_stats AS (
    SELECT
        fhm.forum_id,
        COUNT(DISTINCT fhm.person_id) AS member_count
    FROM forum_has_member_person fhm
    GROUP BY fhm.forum_id
),
post_like_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_like_count
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_like_count
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_tag_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pt.tag_id) AS distinct_post_tag_count
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_tag_stats AS (
    SELECT
        fht.forum_id,
        COUNT(DISTINCT fht.tag_id) AS distinct_forum_tag_count
    FROM forum_has_tag_tag fht
    GROUP BY fht.forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ms.member_count, 0) AS member_count,
    COALESCE(pls.post_like_count, 0) AS post_like_count,
    COALESCE(cls.comment_like_count, 0) AS comment_like_count,
    COALESCE(pts.distinct_post_tag_count, 0) AS distinct_post_tag_count,
    COALESCE(fts.distinct_forum_tag_count, 0) AS distinct_forum_tag_count
FROM forum f
LEFT JOIN post_stats ps ON f.id = ps.forum_id
LEFT JOIN comment_stats cs ON f.id = cs.forum_id
LEFT JOIN member_stats ms ON f.id = ms.forum_id
LEFT JOIN post_like_stats pls ON f.id = pls.forum_id
LEFT JOIN comment_like_stats cls ON f.id = cls.forum_id
LEFT JOIN post_tag_stats pts ON f.id = pts.forum_id
LEFT JOIN forum_tag_stats fts ON f.id = fts.forum_id
ORDER BY post_count DESC
LIMIT 10
