WITH promo_with_reason AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_response_target,
        p.p_discount_active,
        r.r_reason_desc
    FROM promotion p
    JOIN reason r
        ON p.p_response_target = r.r_reason_sk
    WHERE p.p_cost > 1000
      AND p.p_discount_active = 'Y'
),
agg AS (
    SELECT
        cp.cp_type,
        cp.cp_department,
        cp.cp_catalog_number,
        pw.r_reason_desc,
        COUNT(DISTINCT pw.p_promo_id) AS promo_cnt,
        SUM(pw.p_cost) AS total_cost,
        AVG(pw.p_cost) AS avg_cost,
        MIN(pw.p_cost) AS min_cost,
        MAX(pw.p_cost) AS max_cost
    FROM catalog_page cp
    JOIN promo_with_reason pw
        ON cp.cp_start_date_sk <= pw.p_end_date_sk
       AND cp.cp_end_date_sk >= pw.p_start_date_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_catalog_number IN (1, 2, 3)
    GROUP BY cp.cp_type, cp.cp_department, cp.cp_catalog_number, pw.r_reason_desc
    HAVING SUM(pw.p_cost) > 5000
)
SELECT
    a.cp_type,
    a.cp_department,
    a.cp_catalog_number,
    a.r_reason_desc,
    a.promo_cnt,
    a.total_cost,
    a.avg_cost,
    a.min_cost,
    a.max_cost,
    RANK() OVER (ORDER BY a.total_cost DESC) AS cost_rank
FROM agg a
ORDER BY a.total_cost DESC
LIMIT 50
