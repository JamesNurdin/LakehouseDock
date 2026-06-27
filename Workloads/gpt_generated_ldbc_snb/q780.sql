WITH forum_members AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        p.id AS person_id
    FROM forum f
    JOIN forum_has_member_person fmp
        ON fmp.forum_id = f.id
    JOIN person p
        ON fmp.person_id = p.id
),
comment_stats AS (
    SELECT
        fm.forum_id,
        c.id AS comment_id,
        c.length AS comment_length,
        COUNT(plc.person_id) AS like_count
    FROM forum_members fm
    JOIN comment c
        ON c.creator_person_id = fm.person_id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY fm.forum_id, c.id, c.length
),
tag_stats AS (
    SELECT
        fm.forum_id,
        t.name AS tag_name,
        COUNT(DISTINCT fm.person_id) AS member_tag_count
    FROM forum_members fm
    JOIN person_has_interest_tag pit
        ON pit.person_id = fm.person_id
    JOIN tag t
        ON pit.tag_id = t.id
    GROUP BY fm.forum_id, t.name
),
top_tag_per_forum AS (
    SELECT
        ts.forum_id,
        ts.tag_name
    FROM (
        SELECT
            ts.forum_id,
            ts.tag_name,
            ts.member_tag_count,
            ROW_NUMBER() OVER (PARTITION BY ts.forum_id ORDER BY ts.member_tag_count DESC, ts.tag_name) AS rn
        FROM tag_stats ts
    ) ts
    WHERE ts.rn = 1
)
SELECT
    fm.forum_id,
    fm.forum_title,
    COUNT(DISTINCT fm.person_id) AS member_count,
    COUNT(DISTINCT cs.comment_id) AS total_comments,
    COALESCE(SUM(cs.like_count), 0) AS total_comment_likes,
    AVG(cs.comment_length) AS avg_comment_length,
    ttp.tag_name AS top_tag
FROM forum_members fm
LEFT JOIN comment_stats cs
    ON cs.forum_id = fm.forum_id
LEFT JOIN top_tag_per_forum ttp
    ON ttp.forum_id = fm.forum_id
GROUP BY fm.forum_id, fm.forum_title, ttp.tag_name
ORDER BY member_count DESC
LIMIT 10
