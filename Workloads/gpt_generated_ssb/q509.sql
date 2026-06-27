WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        c.c_region AS cust_region,
        c.c_nation AS cust_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supp_region,
        s.s_nation AS supp_nation,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        d_commit.d_year AS commit_year,
        d_commit.d_month AS commit_month
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
    WHERE d_order.d_year = '1994'
)
SELECT
    cust_region,
    p_category,
    order_year,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_details
GROUP BY cust_region, p_category, order_year
ORDER BY total_profit DESC
LIMIT 10
