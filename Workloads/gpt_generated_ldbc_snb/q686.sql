WITH forum_aggregates AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.moderator_person_id,
        MIN(f.creation_date) AS forum_creation_date,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT ft.tag_id) AS tag_count,
        LEAST(
            COALESCE(MIN(f.creation_date), '9999-12-31'),
            COALESCE(MIN(fm.creation_date), '9999-12-31'),
            COALESCE(MIN(ft.creation_date), '9999-12-31')
        ) AS earliest_related_creation_date
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    GROUP BY f.id, f.title, f.moderator_person_id
)
SELECT
    forum_id,
    title,
    moderator_person_id,
    forum_creation_date,
    member_count,
    tag_count,
    earliest_related_creation_date,
    CASE WHEN member_count = 0 THEN NULL
         ELSE CAST(tag_count AS double) / member_count
    END AS tags_per_member_ratio
FROM forum_aggregates
ORDER BY tags_per_member_ratio DESC NULLS LAST, member_count DESC
LIMIT 50
