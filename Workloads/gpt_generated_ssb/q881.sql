WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        c.c_nation AS customer_nation,
        s.s_nation AS supplier_nation,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year,
        p.p_category,
        p.p_color
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d_order.d_year = '1995'
      AND p.p_category = 'MFGR#12'
      AND p.p_color = 'RED'
      AND s.s_region = 'ASIA'
)
SELECT
    customer_nation,
    supplier_nation,
    order_year,
    commit_year,
    p_category,
    p_color,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    SUM(lo_revenue) - SUM(lo_supplycost) AS total_profit
FROM order_data
GROUP BY
    customer_nation,
    supplier_nation,
    order_year,
    commit_year,
    p_category,
    p_color
ORDER BY total_revenue DESC
LIMIT 10
