WITH order_fact AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        d_order.d_year,
        c.c_region,
        p.p_category,
        s.s_nation
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year BETWEEN '1992' AND '1997'
      AND c.c_region = 'AMERICA'
)
SELECT
    d_year,
    c_region,
    p_category,
    s_nation,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(lo_quantity) AS avg_quantity,
    COUNT(DISTINCT lo_orderkey) AS order_cnt
FROM order_fact
GROUP BY d_year, c_region, p_category, s_nation
ORDER BY total_revenue DESC
LIMIT 100
