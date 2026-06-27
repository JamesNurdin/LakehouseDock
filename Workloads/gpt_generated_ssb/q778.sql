WITH revenue_by_year_region_category AS (
    SELECT
        d_order.d_year AS order_year,
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category AS part_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders,
        SUM(lo.lo_quantity) AS total_quantity
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year BETWEEN '1992' AND '1997'
      AND p.p_category = 'MFGR#12'
      AND s.s_region = 'ASIA'
    GROUP BY d_order.d_year, c.c_region, s.s_region, p.p_category
)
SELECT
    order_year,
    customer_region,
    supplier_region,
    part_category,
    total_revenue,
    total_supply_cost,
    total_profit,
    avg_discount,
    distinct_orders,
    total_quantity,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_year_region_category
ORDER BY order_year, revenue_rank
LIMIT 100
