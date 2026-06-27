WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id) AS num_posts,
        COUNT(DISTINCT c.id) AS num_comments,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT plp.person_id) AS num_distinct_post_likers,
        COUNT(DISTINCT plc.person_id) AS num_distinct_comment_likers,
        COUNT(DISTINCT fm.person_id) AS num_members,
        COUNT(DISTINCT pt.tag_id) AS num_distinct_member_tags
    FROM forum AS f
    LEFT JOIN post AS p
        ON p.container_forum_id = f.id
    LEFT JOIN comment AS c
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_post AS plp
        ON plp.post_id = p.id
    LEFT JOIN person_likes_comment AS plc
        ON plc.comment_id = c.id
    LEFT JOIN forum_has_member_person AS fm
        ON fm.forum_id = f.id
    LEFT JOIN person AS per
        ON per.id = fm.person_id
    LEFT JOIN person_has_interest_tag AS pt
        ON pt.person_id = per.id
    GROUP BY f.id, f.title
)
SELECT
    forum_id,
    forum_title,
    num_posts,
    num_comments,
    avg_post_length,
    num_distinct_post_likers,
    num_distinct_comment_likers,
    num_members,
    num_distinct_member_tags
FROM forum_stats
ORDER BY num_posts DESC
LIMIT 10
