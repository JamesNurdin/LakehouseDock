WITH lo_agg AS (
    SELECT lo_partkey,
           SUM(lo_revenue) AS sum_revenue
    FROM lineorder
    GROUP BY lo_partkey
),
ranked_parts AS (
    SELECT p.p_category,
           p.p_brand1,
           p.p_name,
           lo_agg.sum_revenue,
           ROW_NUMBER() OVER (PARTITION BY p.p_category ORDER BY lo_agg.sum_revenue DESC) AS revenue_rank
    FROM lo_agg
    JOIN part p ON lo_agg.lo_partkey = p.p_partkey
    WHERE p.p_category IN ('MFGR#12', 'MFGR#13')
)
SELECT p_category,
       p_brand1,
       p_name,
       sum_revenue,
       revenue_rank
FROM ranked_parts
WHERE revenue_rank <= 5
ORDER BY p_category, revenue_rank
