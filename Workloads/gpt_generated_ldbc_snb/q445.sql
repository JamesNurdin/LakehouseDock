WITH forum_member_tags AS (
    SELECT
        fm.forum_id,
        pit.tag_id
    FROM forum_has_member_person fm
    JOIN person p
        ON fm.person_id = p.id
    JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
),
forum_tags AS (
    SELECT
        ft.forum_id,
        ft.tag_id
    FROM forum_has_tag_tag ft
),
forum_tag_overlap AS (
    SELECT
        ft.forum_id,
        COUNT(DISTINCT ft.tag_id) AS forum_tag_count,
        COUNT(DISTINCT fm.tag_id) AS member_interest_tag_count,
        COUNT(DISTINCT CASE WHEN ft.tag_id = fm.tag_id THEN ft.tag_id END) AS overlap_tag_count
    FROM forum_tags ft
    LEFT JOIN forum_member_tags fm
        ON fm.forum_id = ft.forum_id
        AND fm.tag_id = ft.tag_id
    GROUP BY ft.forum_id
),
forum_member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_post_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(lc.like_count) AS avg_likes_per_post
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN (
        SELECT
            plp.post_id,
            COUNT(*) AS like_count
        FROM person_likes_post plp
        GROUP BY plp.post_id
    ) lc
        ON lc.post_id = p.id
    GROUP BY f.id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    mc.member_count,
    pst.post_count,
    pst.avg_likes_per_post,
    ot.forum_tag_count,
    ot.member_interest_tag_count,
    ot.overlap_tag_count
FROM forum f
LEFT JOIN forum_member_counts mc
    ON mc.forum_id = f.id
LEFT JOIN forum_post_stats pst
    ON pst.forum_id = f.id
LEFT JOIN forum_tag_overlap ot
    ON ot.forum_id = f.id
ORDER BY mc.member_count DESC
LIMIT 20
