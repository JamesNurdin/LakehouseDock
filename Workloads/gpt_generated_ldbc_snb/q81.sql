/*
  Analytical query: forum‑level activity and engagement metrics.
  For each forum we compute:
    • basic info (id, title, moderator name)
    • number of members
    • number of posts and average post length
    • number of comments and average comment length
    • total likes on posts and on comments
    • likes‑per‑post and likes‑per‑comment ratios
    • count of distinct interest‑tag IDs held by forum members
  The result is ordered by the highest likes‑per‑comment ratio and limited to the top 10 forums.
*/
WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN person mod ON f.moderator_person_id = mod.id
    LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id, f.title, mod.first_name, mod.last_name
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(plp.person_id) AS post_like_count
    FROM post p
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(plc.person_id) AS comment_like_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY p.container_forum_id
),
interest_stats AS (
    SELECT
        fm.forum_id AS forum_id,
        COUNT(DISTINCT pit.tag_id) AS distinct_member_interest_tag_count
    FROM forum_has_member_person fm
    JOIN person p2 ON fm.person_id = p2.id
    JOIN person_has_interest_tag pit ON pit.person_id = p2.id
    GROUP BY fm.forum_id
)
SELECT
    fb.forum_id,
    fb.forum_title,
    fb.moderator_first_name,
    fb.moderator_last_name,
    fb.member_count,
    COALESCE(ps.post_count, 0) AS post_count,
    ps.avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    cs.avg_comment_length,
    COALESCE(ps.post_like_count, 0) AS post_like_count,
    COALESCE(cs.comment_like_count, 0) AS comment_like_count,
    CASE WHEN COALESCE(cs.comment_count, 0) = 0 THEN 0
         ELSE COALESCE(cs.comment_like_count, 0) * 1.0 / cs.comment_count END AS likes_per_comment,
    CASE WHEN COALESCE(ps.post_count, 0) = 0 THEN 0
         ELSE COALESCE(ps.post_like_count, 0) * 1.0 / ps.post_count END AS likes_per_post,
    COALESCE(ist.distinct_member_interest_tag_count, 0) AS distinct_member_interest_tag_count
FROM forum_base fb
LEFT JOIN post_stats ps ON ps.forum_id = fb.forum_id
LEFT JOIN comment_stats cs ON cs.forum_id = fb.forum_id
LEFT JOIN interest_stats ist ON ist.forum_id = fb.forum_id
ORDER BY likes_per_comment DESC
LIMIT 10
