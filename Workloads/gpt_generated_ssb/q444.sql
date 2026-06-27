WITH order_fact AS (
    SELECT
        lo.lo_orderkey,
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
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        s.s_nation AS supplier_nation
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
    WHERE CAST(d_commit.d_date AS DATE) BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
)
SELECT
    order_year,
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue) - SUM(lo_supplycost) AS profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    SUM(CASE WHEN lo_discount > 5 THEN lo_revenue ELSE 0 END) AS revenue_high_discount
FROM order_fact
GROUP BY order_year, c_region, p_category
ORDER BY order_year, c_region, p_category
