WITH person_info_agg AS (
    SELECT
        p.person_id AS person_id,
        COUNT(*) AS info_cnt,
        COUNT(DISTINCT p.info_type_id) AS distinct_info_type_cnt,
        AVG(LENGTH(p.info)) AS avg_info_len
    FROM person_info p
    WHERE p.info IS NOT NULL
    GROUP BY p.person_id
)
SELECT
    n.id,
    n.name,
    n.gender,
    a.info_cnt,
    a.distinct_info_type_cnt,
    a.avg_info_len,
    RANK() OVER (ORDER BY a.info_cnt DESC) AS info_cnt_rank
FROM name n
JOIN person_info_agg a ON a.person_id = n.id
WHERE n.gender IS NOT NULL
ORDER BY a.info_cnt DESC
LIMIT 20
