WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d1.d_year AS order_year,
        d1.d_date AS order_date,
        d2.d_year AS commit_year,
        d2.d_date AS commit_date,
        c.c_region,
        c.c_nation,
        p.p_brand1,
        p.p_category,
        s.s_nation AS supplier_nation
    FROM lineorder lo
    JOIN dim_date d1
        ON CAST(lo.lo_orderdate AS VARCHAR) = d1.d_datekey
    JOIN dim_date d2
        ON CAST(lo.lo_commitdate AS VARCHAR) = d2.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d1.d_year = '1995'
      AND c.c_region = 'ASIA'
      AND p.p_category = 'MFGR#1'
)
SELECT
    order_year,
    c_region,
    p_brand1,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS profit,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', DATE(order_date), DATE(commit_date))) AS avg_days_to_commit,
    COUNT(*) AS order_count
FROM order_info
GROUP BY order_year, c_region, p_brand1
ORDER BY total_revenue DESC
LIMIT 20
