WITH lo_joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        lo.lo_orderpriority,
        d_ord.d_year,
        d_ord.d_date AS order_date,
        d_com.d_date AS commit_date,
        c.c_region,
        c.c_mktsegment,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d_ord
        ON lo.lo_orderdate = CAST(d_ord.d_datekey AS integer)
    JOIN dim_date d_com
        ON lo.lo_commitdate = CAST(d_com.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_ord.d_year = '1995'
)
SELECT
    d_year,
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(order_date AS date), CAST(commit_date AS date))) AS avg_lead_days,
    SUM(lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM lo_joined
GROUP BY d_year, c_region, p_category
ORDER BY total_revenue DESC
LIMIT 20
