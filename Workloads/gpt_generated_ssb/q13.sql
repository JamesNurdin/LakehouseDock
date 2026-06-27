WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_partkey,
        lo.lo_suppkey,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE CAST(d.d_date AS DATE) >= DATE '1995-01-01'
      AND CAST(d.d_date AS DATE) < DATE '1996-01-01'
)
SELECT
    fo.d_year AS order_year,
    s.s_region AS supplier_region,
    p.p_category AS product_category,
    SUM(fo.lo_revenue) AS total_revenue,
    SUM(fo.lo_supplycost) AS total_supply_cost,
    SUM(fo.lo_revenue - fo.lo_supplycost) AS total_profit,
    SUM(fo.lo_quantity) AS total_quantity,
    AVG(fo.lo_discount) AS avg_discount,
    COUNT(DISTINCT fo.lo_orderkey) AS distinct_orders
FROM filtered_orders fo
JOIN part p
    ON fo.lo_partkey = p.p_partkey
JOIN supplier s
    ON fo.lo_suppkey = s.s_suppkey
GROUP BY
    fo.d_year,
    s.s_region,
    p.p_category
ORDER BY
    fo.d_year,
    s.s_region,
    p.p_category
