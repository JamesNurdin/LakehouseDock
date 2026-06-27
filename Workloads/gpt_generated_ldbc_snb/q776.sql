WITH member_stats AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT CASE WHEN p.gender = 'male' THEN p.id END) AS male_member_count,
        COUNT(DISTINCT CASE WHEN p.gender = 'female' THEN p.id END) AS female_member_count
    FROM forum_has_member_person fm
    JOIN person p ON fm.person_id = p.id
    GROUP BY fm.forum_id
),

tag_stats AS (
    SELECT
        ft.forum_id,
        COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),

post_stats AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(DISTINCT po.id) AS post_count,
        SUM(po.length) AS total_post_length,
        AVG(po.length) AS avg_post_length
    FROM post po
    GROUP BY po.container_forum_id
),

comment_stats AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post po ON c.parent_post_id = po.id
    GROUP BY po.container_forum_id
),

post_like_stats AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(*) AS post_like_count
    FROM person_likes_post plp
    JOIN post po ON plp.post_id = po.id
    GROUP BY po.container_forum_id
),

comment_like_stats AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(*) AS comment_like_count
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post po ON c.parent_post_id = po.id
    GROUP BY po.container_forum_id
),

member_interest_stats AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT p.id) AS members_with_interest_count
    FROM forum_has_member_person fm
    JOIN person p ON fm.person_id = p.id
    JOIN person_has_interest_tag pit ON p.id = pit.person_id
    WHERE pit.tag_id = 100
    GROUP BY fm.forum_id
)
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date,
    COALESCE(ms.member_count, 0) AS member_count,
    COALESCE(ms.male_member_count, 0) AS male_member_count,
    COALESCE(ms.female_member_count, 0) AS female_member_count,
    COALESCE(ts.tag_count, 0) AS tag_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_length, 0) AS total_post_length,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_length, 0) AS total_comment_length,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pls.post_like_count, 0) AS post_like_count,
    COALESCE(cls.comment_like_count, 0) AS comment_like_count,
    COALESCE(mis.members_with_interest_count, 0) AS members_with_interest_tag_100
FROM forum f
LEFT JOIN member_stats ms ON f.id = ms.forum_id
LEFT JOIN tag_stats ts ON f.id = ts.forum_id
LEFT JOIN post_stats ps ON f.id = ps.forum_id
LEFT JOIN comment_stats cs ON f.id = cs.forum_id
LEFT JOIN post_like_stats pls ON f.id = pls.forum_id
LEFT JOIN comment_like_stats cls ON f.id = cls.forum_id
LEFT JOIN member_interest_stats mis ON f.id = mis.forum_id
ORDER BY member_count DESC
LIMIT 10
