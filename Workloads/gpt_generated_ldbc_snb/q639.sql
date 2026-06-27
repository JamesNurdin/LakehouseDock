WITH forum_info AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        mod.gender AS moderator_gender
    FROM forum f
    JOIN person mod ON f.moderator_person_id = mod.id
),
member_tag_counts AS (
    SELECT
        fmp.forum_id,
        p.id AS person_id,
        p.gender AS gender,
        COUNT(pht.tag_id) AS tag_count
    FROM forum_has_member_person fmp
    JOIN person p ON fmp.person_id = p.id
    LEFT JOIN person_has_interest_tag pht ON p.id = pht.person_id
    GROUP BY fmp.forum_id, p.id, p.gender
),
distinct_tags AS (
    SELECT
        fmp.forum_id,
        COUNT(DISTINCT pht.tag_id) AS distinct_tag_count
    FROM forum_has_member_person fmp
    JOIN person_has_interest_tag pht ON fmp.person_id = pht.person_id
    GROUP BY fmp.forum_id
)
SELECT
    fi.forum_id,
    fi.forum_title,
    fi.moderator_first_name,
    fi.moderator_last_name,
    fi.moderator_gender,
    COUNT(mtc.person_id) AS member_count,
    SUM(CASE WHEN mtc.gender = 'male' THEN 1 ELSE 0 END) AS male_member_count,
    SUM(CASE WHEN mtc.gender = 'female' THEN 1 ELSE 0 END) AS female_member_count,
    SUM(mtc.tag_count) AS total_tag_assignments,
    AVG(mtc.tag_count) AS avg_tags_per_member,
    dt.distinct_tag_count
FROM forum_info fi
JOIN member_tag_counts mtc ON fi.forum_id = mtc.forum_id
LEFT JOIN distinct_tags dt ON fi.forum_id = dt.forum_id
GROUP BY
    fi.forum_id,
    fi.forum_title,
    fi.moderator_first_name,
    fi.moderator_last_name,
    fi.moderator_gender,
    dt.distinct_tag_count
ORDER BY member_count DESC
LIMIT 10
