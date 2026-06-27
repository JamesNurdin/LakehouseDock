WITH post_counts AS (
    SELECT
        t.id AS tag_id,
        COUNT(p.id) AS post_cnt,
        COUNT(DISTINCT p.creator_person_id) AS post_creator_cnt,
        AVG(p.length) AS avg_post_length
    FROM tag t
    JOIN post_has_tag_tag pt ON pt.tag_id = t.id
    JOIN post p ON p.id = pt.post_id
    GROUP BY t.id
),
comment_counts AS (
    SELECT
        t.id AS tag_id,
        COUNT(c.id) AS comment_cnt,
        COUNT(DISTINCT c.creator_person_id) AS comment_creator_cnt,
        AVG(c.length) AS avg_comment_length
    FROM tag t
    JOIN comment_has_tag_tag ct ON ct.tag_id = t.id
    JOIN comment c ON c.id = ct.comment_id
    GROUP BY t.id
),
forum_counts AS (
    SELECT
        t.id AS tag_id,
        COUNT(f.id) AS forum_cnt,
        COUNT(DISTINCT f.moderator_person_id) AS forum_mod_cnt
    FROM tag t
    JOIN forum_has_tag_tag ft ON ft.tag_id = t.id
    JOIN forum f ON f.id = ft.forum_id
    GROUP BY t.id
),
interest_counts AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.id) AS interest_person_cnt
    FROM tag t
    JOIN person_has_interest_tag pit ON pit.tag_id = t.id
    JOIN person p ON p.id = pit.person_id
    GROUP BY t.id
)
SELECT
    t.name AS tag_name,
    tc.name AS tag_class_name,
    COALESCE(pc.post_cnt, 0) AS post_count,
    COALESCE(pc.post_creator_cnt, 0) AS post_creator_count,
    COALESCE(pc.avg_post_length, 0) AS avg_post_length,
    COALESCE(cc.comment_cnt, 0) AS comment_count,
    COALESCE(cc.comment_creator_cnt, 0) AS comment_creator_count,
    COALESCE(cc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(fc.forum_cnt, 0) AS forum_count,
    COALESCE(fc.forum_mod_cnt, 0) AS forum_mod_count,
    COALESCE(ic.interest_person_cnt, 0) AS interested_person_count
FROM tag t
LEFT JOIN tag_class tc ON tc.id = t.type_tag_class_id
LEFT JOIN post_counts pc ON pc.tag_id = t.id
LEFT JOIN comment_counts cc ON cc.tag_id = t.id
LEFT JOIN forum_counts fc ON fc.tag_id = t.id
LEFT JOIN interest_counts ic ON ic.tag_id = t.id
ORDER BY post_count DESC, comment_count DESC
LIMIT 100
