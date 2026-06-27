WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d.d_year AS order_year,
        c.c_nation AS cust_nation,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
),
agg AS (
    SELECT
        order_year,
        cust_nation,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS order_cnt
    FROM order_details
    WHERE p_category = 'MFGR#1'
      AND s_region = 'ASIA'
      AND order_year BETWEEN '1992' AND '1997'
    GROUP BY order_year, cust_nation
)
SELECT
    order_year,
    cust_nation,
    total_revenue,
    total_profit,
    avg_discount,
    order_cnt,
    total_revenue / SUM(total_revenue) OVER (PARTITION BY order_year) AS revenue_share
FROM agg
ORDER BY total_revenue DESC
LIMIT 100
