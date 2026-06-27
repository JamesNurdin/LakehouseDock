WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        c.c_region,
        c.c_nation,
        p.p_mfgr,
        p.p_category,
        s.s_nation AS supplier_nation,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year,
        (lo.lo_extendedprice * (100 - lo.lo_discount) / 100) AS revenue,
        ((lo.lo_extendedprice * (100 - lo.lo_discount) / 100) - lo.lo_supplycost * lo.lo_quantity) AS profit
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE p.p_mfgr = 'MFGR#1'
      AND d_order.d_year = '1994'
)
SELECT
    order_year,
    supplier_nation,
    SUM(revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    COUNT(*) AS order_count
FROM order_data
GROUP BY order_year, supplier_nation
ORDER BY total_revenue DESC
LIMIT 10
