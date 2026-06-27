WITH order_data AS (
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
        d_order.d_date AS order_date,
        d_commit.d_year AS commit_year,
        d_commit.d_date AS commit_date,
        c.c_region AS customer_region,
        c.c_nation AS customer_nation,
        s.s_region AS supplier_region,
        s.s_nation AS supplier_nation,
        p.p_category AS part_category,
        p.p_brand1 AS part_brand,
        p.p_mfgr AS part_mfgr
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d_order.d_year = '1995'
      AND p.p_category = 'MFGR#12'
)
SELECT
    order_year,
    supplier_region,
    part_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_data
GROUP BY order_year, supplier_region, part_category
ORDER BY total_revenue DESC
LIMIT 10
