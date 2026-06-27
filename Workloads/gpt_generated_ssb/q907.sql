WITH lo_joined AS (
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
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        d_commit.d_year AS commit_year,
        d_commit.d_month AS commit_month,
        p.p_category,
        p.p_brand1,
        s.s_region,
        s.s_nation
    FROM lineorder lo
    LEFT JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
    LEFT JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS INTEGER) = lo.lo_commitdate
    LEFT JOIN part p
        ON lo.lo_partkey = p.p_partkey
    LEFT JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year = '1995'
)
SELECT
    order_year,
    order_month,
    p_category,
    s_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM lo_joined
GROUP BY
    order_year,
    order_month,
    p_category,
    s_region
ORDER BY
    total_revenue DESC
LIMIT 20
