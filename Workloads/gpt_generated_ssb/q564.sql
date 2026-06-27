WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d_order.d_year AS order_year,
        c.c_region AS customer_region,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE p.p_category = 'MFGR#12'
)
SELECT
    order_year,
    customer_region,
    supplier_region,
    COUNT(DISTINCT lo_orderkey) AS order_cnt,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount
FROM order_info
WHERE order_year = '1995'
GROUP BY order_year, customer_region, supplier_region
ORDER BY total_profit DESC
LIMIT 20
