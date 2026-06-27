WITH forum_info AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person p
        ON f.moderator_person_id = p.id
),
post_stats AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(po.length) AS avg_post_length,
        COUNT(DISTINCT po.creator_person_id) AS participant_count
    FROM post po
    GROUP BY po.container_forum_id
),
tag_stats AS (
    SELECT
        fht.forum_id AS forum_id,
        COUNT(DISTINCT fht.tag_id) AS tag_count
    FROM forum_has_tag_tag fht
    GROUP BY fht.forum_id
)
SELECT
    fi.forum_id,
    fi.forum_title,
    fi.forum_creation_date,
    fi.moderator_first_name,
    fi.moderator_last_name,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(ps.participant_count, 0) AS participant_count,
    COALESCE(ts.tag_count, 0) AS tag_count
FROM forum_info fi
LEFT JOIN post_stats ps
    ON fi.forum_id = ps.forum_id
LEFT JOIN tag_stats ts
    ON fi.forum_id = ts.forum_id
ORDER BY post_count DESC
LIMIT 10
