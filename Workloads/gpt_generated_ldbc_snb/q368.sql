WITH post_stats AS (
    SELECT
        f.id AS forum_id,
        f.title,
        p_mod.first_name AS moderator_first_name,
        p_mod.last_name AS moderator_last_name,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count
    FROM forum f
    JOIN person p_mod ON f.moderator_person_id = p_mod.id
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id, f.title, p_mod.first_name, p_mod.last_name
),

tag_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT pht.tag_id) AS distinct_tag_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN person p_creator ON p.creator_person_id = p_creator.id
    LEFT JOIN person_has_interest_tag pht ON p_creator.id = pht.person_id
    GROUP BY f.id
),

language_counts AS (
    SELECT
        f.id AS forum_id,
        p.language,
        COUNT(*) AS language_post_count,
        ROW_NUMBER() OVER (PARTITION BY f.id ORDER BY COUNT(*) DESC) AS rn
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id, p.language
)
SELECT
    ps.forum_id,
    ps.title,
    ps.moderator_first_name,
    ps.moderator_last_name,
    ps.post_count,
    ps.avg_post_length,
    ps.distinct_creator_count,
    ts.distinct_tag_count,
    lc.language AS top_language,
    lc.language_post_count AS top_language_post_count
FROM post_stats ps
LEFT JOIN tag_stats ts ON ps.forum_id = ts.forum_id
LEFT JOIN language_counts lc ON ps.forum_id = lc.forum_id AND lc.rn = 1
ORDER BY ps.post_count DESC
LIMIT 20
