WITH
    forum_member_counts AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum f
        JOIN forum_has_member_person fm ON fm.forum_id = f.id
        GROUP BY f.id
    ),
    post_tag_stats AS (
        SELECT
            f.id AS forum_id,
            f.title AS forum_title,
            t.id AS tag_id,
            t.name AS tag_name,
            COUNT(p.id) AS post_count,
            COUNT(DISTINCT p.creator_person_id) AS creator_person_count
        FROM post p
        JOIN forum f ON p.container_forum_id = f.id
        JOIN post_has_tag_tag pt ON pt.post_id = p.id
        JOIN tag t ON pt.tag_id = t.id
        GROUP BY f.id, f.title, t.id, t.name
    ),
    tag_interest_counts AS (
        SELECT
            t.id AS tag_id,
            COUNT(DISTINCT p.id) AS interest_person_count
        FROM tag t
        JOIN person_has_interest_tag pi ON pi.tag_id = t.id
        JOIN person p ON pi.person_id = p.id
        GROUP BY t.id
    ),
    comment_tag_counts AS (
        SELECT
            t.id AS tag_id,
            COUNT(c.comment_id) AS comment_count
        FROM tag t
        JOIN comment_has_tag_tag c ON c.tag_id = t.id
        GROUP BY t.id
    ),
    tag_class_info AS (
        SELECT
            t.id AS tag_id,
            tc.name AS tag_class_name
        FROM tag t
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
    )
SELECT
    pts.forum_title,
    pts.tag_name,
    tci.tag_class_name,
    pts.post_count,
    pts.creator_person_count,
    fmc.member_count,
    tic.interest_person_count,
    ctc.comment_count
FROM post_tag_stats pts
JOIN forum_member_counts fmc ON fmc.forum_id = pts.forum_id
LEFT JOIN tag_interest_counts tic ON tic.tag_id = pts.tag_id
LEFT JOIN comment_tag_counts ctc ON ctc.tag_id = pts.tag_id
LEFT JOIN tag_class_info tci ON tci.tag_id = pts.tag_id
ORDER BY pts.forum_title, pts.post_count DESC
LIMIT 100
