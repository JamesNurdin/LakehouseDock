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
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        c.c_region AS cust_region,
        c.c_nation AS cust_nation,
        s.s_region AS supp_region,
        s.s_nation AS supp_nation,
        p.p_category,
        p.p_brand1,
        od.d_year AS order_year,
        od.d_month AS order_month,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN dim_date od ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
    WHERE od.d_year = '1995'
),
aggregated AS (
    SELECT
        cust_region,
        supp_region,
        order_year,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supply_cost,
        SUM(lo_revenue - lo_supplycost - lo_tax) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders
    FROM order_details
    GROUP BY cust_region, supp_region, order_year, p_category
)
SELECT
    cust_region,
    supp_region,
    order_year,
    p_category,
    total_revenue,
    total_supply_cost,
    total_profit,
    avg_discount,
    distinct_orders,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_profit DESC
LIMIT 10
