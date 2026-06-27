WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        od.d_year AS order_year,
        od.d_month AS order_month,
        cd.d_year AS commit_year,
        cd.d_month AS commit_month,
        c.c_region AS c_region,
        c.c_nation AS c_nation,
        p.p_category AS p_category,
        p.p_brand1 AS p_brand1,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
),
agg AS (
    SELECT
        order_year,
        c_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS num_orders,
        COUNT(DISTINCT lo_suppkey) AS num_suppliers
    FROM order_details
    GROUP BY order_year, c_region, p_category
)
SELECT
    order_year,
    c_region,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    num_orders,
    num_suppliers,
    RANK() OVER (PARTITION BY order_year, c_region ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY order_year, c_region, revenue_rank
LIMIT 100
