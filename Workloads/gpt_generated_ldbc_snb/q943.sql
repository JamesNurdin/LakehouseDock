/* Top 10 forums by post count with moderator, member, tag and post statistics */
WITH forum_info AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        p_mod.first_name AS moderator_first_name,
        p_mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person p_mod
        ON f.moderator_person_id = p_mod.id
),

forum_member_counts AS (
    SELECT
        fmp.forum_id,
        COUNT(DISTINCT p.id) AS member_count
    FROM forum_has_member_person fmp
    LEFT JOIN person p
        ON fmp.person_id = p.id
    GROUP BY fmp.forum_id
),

forum_post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),

forum_tag_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM post p
    LEFT JOIN post_has_tag_tag pht
        ON p.id = pht.post_id
    LEFT JOIN tag t
        ON pht.tag_id = t.id
    GROUP BY p.container_forum_id
),

forum_tag_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(p.id) AS tag_post_cnt
    FROM post p
    LEFT JOIN post_has_tag_tag pht
        ON p.id = pht.post_id
    LEFT JOIN tag t
        ON pht.tag_id = t.id
    GROUP BY p.container_forum_id, t.id, t.name
),

forum_top_tag AS (
    SELECT
        ftc.forum_id,
        ftc.tag_name,
        ftc.tag_post_cnt,
        ROW_NUMBER() OVER (PARTITION BY ftc.forum_id ORDER BY ftc.tag_post_cnt DESC) AS rn
    FROM forum_tag_counts ftc
),

forum_top_tag_filtered AS (
    SELECT
        forum_id,
        tag_name AS top_tag_name,
        tag_post_cnt AS top_tag_post_count
    FROM forum_top_tag
    WHERE rn = 1
)

SELECT
    fi.forum_id,
    fi.forum_title,
    fi.moderator_first_name,
    fi.moderator_last_name,
    COALESCE(fmc.member_count, 0) AS member_count,
    COALESCE(fps.post_count, 0) AS post_count,
    fps.avg_post_length,
    COALESCE(fts.distinct_tag_count, 0) AS distinct_tag_count,
    ftt.top_tag_name,
    ftt.top_tag_post_count
FROM forum_info fi
LEFT JOIN forum_member_counts fmc
    ON fi.forum_id = fmc.forum_id
LEFT JOIN forum_post_stats fps
    ON fi.forum_id = fps.forum_id
LEFT JOIN forum_tag_stats fts
    ON fi.forum_id = fts.forum_id
LEFT JOIN forum_top_tag_filtered ftt
    ON fi.forum_id = ftt.forum_id
ORDER BY post_count DESC
LIMIT 10
