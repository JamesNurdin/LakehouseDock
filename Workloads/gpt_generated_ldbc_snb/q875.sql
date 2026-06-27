WITH post_likes AS (
    SELECT
        p.id AS post_id,
        p.length AS post_length,
        p.creator_person_id,
        p.container_forum_id,
        COUNT(pl.person_id) AS like_count
    FROM post p
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY p.id, p.length, p.creator_person_id, p.container_forum_id
)
SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    tc.name AS tag_class_name,
    COUNT(DISTINCT pl.post_id) AS post_count,
    SUM(pl.like_count) AS total_likes,
    AVG(pl.post_length) AS avg_post_length,
    COUNT(DISTINCT pl.creator_person_id) AS distinct_authors,
    COUNT(DISTINCT f.id) AS distinct_forums,
    AVG(fm.member_count) AS avg_forum_members
FROM post_likes pl
JOIN post_has_tag_tag pht ON pht.post_id = pl.post_id
JOIN tag t ON t.id = pht.tag_id
JOIN tag_class tc ON tc.id = t.type_tag_class_id
LEFT JOIN forum f ON f.id = pl.container_forum_id
LEFT JOIN (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
) fm ON fm.forum_id = f.id
GROUP BY t.id, t.name, tc.name
ORDER BY total_likes DESC
LIMIT 10
