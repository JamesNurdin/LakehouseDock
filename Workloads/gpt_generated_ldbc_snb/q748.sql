WITH forum_members AS (
    SELECT f.id AS forum_id,
           f.title,
           f.creation_date AS forum_creation_date,
           f.moderator_person_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id, f.title, f.creation_date, f.moderator_person_id
),
forum_tags AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT ft.tag_id) AS tag_count,
           COUNT(DISTINCT tc.id) AS tag_class_count
    FROM forum f
    LEFT JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    LEFT JOIN tag t
        ON t.id = ft.tag_id
    LEFT JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
    GROUP BY f.id
),
forum_member_interest_overlap AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS overlap_member_count
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    JOIN person_has_interest_tag pi
        ON pi.person_id = fm.person_id
    JOIN tag t
        ON t.id = pi.tag_id
    JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
        AND ft.tag_id = t.id
    GROUP BY f.id
),
forum_comment_tag_overlap AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT ch.comment_id) AS comment_overlap_count
    FROM forum f
    JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    JOIN tag t
        ON t.id = ft.tag_id
    JOIN comment_has_tag_tag ch
        ON ch.tag_id = t.id
    GROUP BY f.id
)
SELECT fm.forum_id,
       fm.title,
       fm.forum_creation_date,
       fm.moderator_person_id,
       fm.member_count,
       ft.tag_count,
       ft.tag_class_count,
       COALESCE(fmi.overlap_member_count, 0) AS overlap_member_count,
       COALESCE(fct.comment_overlap_count, 0) AS comment_overlap_count
FROM forum_members fm
LEFT JOIN forum_tags ft
    ON ft.forum_id = fm.forum_id
LEFT JOIN forum_member_interest_overlap fmi
    ON fmi.forum_id = fm.forum_id
LEFT JOIN forum_comment_tag_overlap fct
    ON fct.forum_id = fm.forum_id
ORDER BY fm.member_count DESC, fm.title
