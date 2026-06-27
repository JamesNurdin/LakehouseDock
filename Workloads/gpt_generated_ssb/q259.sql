WITH brand_revenue AS (
    SELECT
        p.p_category,
        p.p_brand1,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS brand_revenue,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) - lo.lo_supplycost) AS brand_profit,
        COUNT(*) AS order_lines
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_quantity BETWEEN 1 AND 50
      AND lo.lo_discount BETWEEN 0 AND 5
    GROUP BY p.p_category, p.p_brand1
)
SELECT
    p_category,
    p_brand1,
    brand_revenue,
    brand_profit,
    order_lines,
    brand_revenue / SUM(brand_revenue) OVER () AS revenue_share,
    ROW_NUMBER() OVER (ORDER BY brand_revenue DESC) AS revenue_rank
FROM brand_revenue
ORDER BY brand_revenue DESC
LIMIT 10
