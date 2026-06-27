WITH aggregated AS (
    SELECT
        s.s_region AS supplier_region,
        d_order.d_year AS order_year,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_tax) AS total_tax,
        SUM(lo.lo_quantity) AS total_quantity,
        SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) - SUM(lo.lo_tax) AS profit,
        AVG(lo.lo_discount) AS avg_discount
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
    WHERE d_order.d_year = '1995'
      AND p.p_category = 'MFGR#1'
    GROUP BY s.s_region, d_order.d_year, p.p_category
)
SELECT
    supplier_region,
    order_year,
    p_category,
    total_revenue,
    total_supplycost,
    total_tax,
    total_quantity,
    profit,
    avg_discount,
    RANK() OVER (PARTITION BY supplier_region, order_year ORDER BY profit DESC) AS profit_rank
FROM aggregated
ORDER BY supplier_region, order_year, profit_rank
LIMIT 20
