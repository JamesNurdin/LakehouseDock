WITH
    forum_base AS (
        SELECT
            f.id,
            f.title,
            f.creation_date,
            f.moderator_person_id
        FROM forum f
    ),
    moderator_info AS (
        SELECT
            fb.id AS forum_id,
            p.first_name AS moderator_first_name,
            p.last_name  AS moderator_last_name
        FROM forum_base fb
        JOIN person p
            ON fb.moderator_person_id = p.id
    ),
    member_counts AS (
        SELECT
            fhmp.forum_id,
            COUNT(DISTINCT fhmp.person_id) AS member_count
        FROM forum_has_member_person fhmp
        GROUP BY fhmp.forum_id
    ),
    tag_counts AS (
        SELECT
            fht.forum_id,
            COUNT(DISTINCT fht.tag_id) AS tag_count
        FROM forum_has_tag_tag fht
        GROUP BY fht.forum_id
    ),
    post_aggregates AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS total_posts,
            SUM(p.length) AS total_post_length,
            AVG(p.length) AS avg_post_length,
            COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count
        FROM post p
        GROUP BY p.container_forum_id
    ),
    post_contributor_counts AS (
        SELECT
            p.container_forum_id AS forum_id,
            p.creator_person_id,
            COUNT(*) AS post_cnt
        FROM post p
        GROUP BY p.container_forum_id, p.creator_person_id
    ),
    top_contributor AS (
        SELECT
            pc.forum_id,
            pc.creator_person_id AS top_contributor_id,
            pc.post_cnt AS top_contributor_post_count
        FROM (
            SELECT
                pc.*, 
                ROW_NUMBER() OVER (PARTITION BY pc.forum_id ORDER BY pc.post_cnt DESC) AS rn
            FROM post_contributor_counts pc
        ) pc
        WHERE pc.rn = 1
    ),
    top_contributor_info AS (
        SELECT
            tc.forum_id,
            p.first_name AS top_contributor_first_name,
            p.last_name  AS top_contributor_last_name,
            tc.top_contributor_post_count
        FROM top_contributor tc
        JOIN person p
            ON tc.top_contributor_id = p.id
    )
SELECT
    fb.id AS forum_id,
    fb.title,
    fb.creation_date,
    mi.moderator_first_name,
    mi.moderator_last_name,
    COALESCE(mc.member_count, 0)               AS member_count,
    COALESCE(tc.tag_count, 0)                  AS tag_count,
    COALESCE(pa.total_posts, 0)                AS total_posts,
    COALESCE(pa.total_post_length, 0)          AS total_post_length,
    COALESCE(pa.avg_post_length, 0)            AS avg_post_length,
    COALESCE(pa.distinct_creator_count, 0)    AS distinct_creator_count,
    tci.top_contributor_first_name,
    tci.top_contributor_last_name,
    COALESCE(tci.top_contributor_post_count, 0) AS top_contributor_post_count
FROM forum_base fb
LEFT JOIN moderator_info mi
    ON fb.id = mi.forum_id
LEFT JOIN member_counts mc
    ON fb.id = mc.forum_id
LEFT JOIN tag_counts tc
    ON fb.id = tc.forum_id
LEFT JOIN post_aggregates pa
    ON fb.id = pa.forum_id
LEFT JOIN top_contributor_info tci
    ON fb.id = tci.forum_id
ORDER BY fb.creation_date DESC
LIMIT 100
