WITH order_data AS (
    SELECT
        d_order.d_year,
        d_order.d_month,
        c.c_region,
        p.p_category,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_orderkey
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d_order.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND CAST(d_commit.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    d_year,
    d_month,
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    COUNT(*) AS lineitem_count,
    CASE WHEN SUM(lo_revenue) = 0 THEN 0 ELSE SUM(lo_revenue - lo_supplycost) / SUM(lo_revenue) END AS profit_margin
FROM order_data
GROUP BY d_year, d_month, c_region, p_category
ORDER BY total_revenue DESC
LIMIT 50
