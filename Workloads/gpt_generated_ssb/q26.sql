WITH filtered_lo AS (
    SELECT lo.lo_partkey,
           lo.lo_quantity,
           lo.lo_revenue,
           lo.lo_discount
    FROM lineorder lo
    WHERE lo.lo_shipmode = 'AIR'
), part_agg AS (
    SELECT p.p_category,
           p.p_brand1,
           p.p_color,
           sum(fl.lo_revenue) AS total_revenue,
           avg(fl.lo_discount) AS avg_discount,
           sum(fl.lo_quantity) AS total_quantity
    FROM filtered_lo fl
    JOIN part p
      ON fl.lo_partkey = p.p_partkey
    GROUP BY p.p_category, p.p_brand1, p.p_color
)
SELECT pa.p_category,
       pa.p_brand1,
       pa.p_color,
       pa.total_revenue,
       pa.avg_discount,
       pa.total_quantity,
       rank() OVER (ORDER BY pa.total_revenue DESC) AS revenue_rank
FROM part_agg pa
ORDER BY pa.total_revenue DESC
LIMIT 20
