WITH comment_stats AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS comment_cnt,
        AVG(c.length) AS avg_comment_len,
        COUNT(DISTINCT c.parent_comment_id) AS distinct_parent_comment_cnt
    FROM comment c
    GROUP BY c.creator_person_id
),
friend_stats AS (
    SELECT
        kp.person1_id AS person_id,
        COUNT(*) AS friends_cnt
    FROM person_knows_person kp
    GROUP BY kp.person1_id
),
tag_stats AS (
    SELECT
        pit.person_id,
        COUNT(*) AS tag_cnt
    FROM person_has_interest_tag pit
    GROUP BY pit.person_id
),
company_stats AS (
    SELECT
        pwc.person_id,
        COUNT(DISTINCT pwc.company_id) AS company_cnt
    FROM person_work_at_company pwc
    GROUP BY pwc.person_id
),
forum_stats AS (
    SELECT
        fmp.person_id,
        COUNT(DISTINCT fmp.forum_id) AS forum_cnt
    FROM forum_has_member_person fmp
    GROUP BY fmp.person_id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    COALESCE(cs.comment_cnt, 0) AS comment_cnt,
    COALESCE(cs.avg_comment_len, 0) AS avg_comment_len,
    COALESCE(fs.friends_cnt, 0) AS friends_cnt,
    COALESCE(ts.tag_cnt, 0) AS tag_cnt,
    COALESCE(comp.company_cnt, 0) AS company_cnt,
    COALESCE(fm.forum_cnt, 0) AS forum_cnt,
    RANK() OVER (ORDER BY COALESCE(cs.comment_cnt, 0) DESC) AS comment_rank
FROM person p
LEFT JOIN comment_stats cs   ON cs.person_id = p.id
LEFT JOIN friend_stats   fs   ON fs.person_id = p.id
LEFT JOIN tag_stats      ts   ON ts.person_id = p.id
LEFT JOIN company_stats  comp ON comp.person_id = p.id
LEFT JOIN forum_stats    fm   ON fm.person_id = p.id
ORDER BY comment_cnt DESC
LIMIT 20
