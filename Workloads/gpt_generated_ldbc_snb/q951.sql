WITH
    post_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS total_posts,
            AVG(p.length) AS avg_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),
    likes_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(plp.person_id) AS total_likes
        FROM post p
        LEFT JOIN person_likes_post plp
            ON plp.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    comment_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS total_comments
        FROM comment c
        JOIN post p
            ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    member_stats AS (
        SELECT
            fm.forum_id,
            COUNT(DISTINCT fm.person_id) AS distinct_member_count
        FROM forum_has_member_person fm
        GROUP BY fm.forum_id
    ),
    tag_stats AS (
        SELECT
            ft.forum_id,
            COUNT(DISTINCT ft.tag_id) AS distinct_tag_count
        FROM forum_has_tag_tag ft
        GROUP BY ft.forum_id
    ),
    creator_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            p.creator_person_id AS person_id,
            COUNT(*) AS post_count
        FROM post p
        GROUP BY p.container_forum_id, p.creator_person_id
    ),
    top_creator AS (
        SELECT
            forum_id,
            person_id AS top_creator_person_id,
            post_count AS top_creator_post_count
        FROM (
            SELECT
                cs.forum_id,
                cs.person_id,
                cs.post_count,
                ROW_NUMBER() OVER (PARTITION BY cs.forum_id ORDER BY cs.post_count DESC) AS rn
            FROM creator_stats cs
        ) t
        WHERE rn = 1
    )
SELECT
    f.id AS forum_id,
    f.title,
    COALESCE(ps.total_posts, 0) AS total_posts,
    COALESCE(cs.total_comments, 0) AS total_comments,
    COALESCE(ms.distinct_member_count, 0) AS distinct_member_count,
    COALESCE(ts.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(ls.total_likes, 0) AS total_likes,
    tc.top_creator_person_id,
    tc.top_creator_post_count
FROM forum f
LEFT JOIN post_stats ps ON ps.forum_id = f.id
LEFT JOIN comment_stats cs ON cs.forum_id = f.id
LEFT JOIN member_stats ms ON ms.forum_id = f.id
LEFT JOIN tag_stats ts ON ts.forum_id = f.id
LEFT JOIN likes_stats ls ON ls.forum_id = f.id
LEFT JOIN top_creator tc ON tc.forum_id = f.id
ORDER BY total_posts DESC
