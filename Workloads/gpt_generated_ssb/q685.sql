WITH joined_data AS (
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
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year,
        cust.c_region AS cust_region,
        supp.s_region AS supp_region,
        p.p_category
    FROM lineorder AS lo
    JOIN dim_date AS d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date AS d_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
    JOIN customer AS cust
        ON lo.lo_custkey = cust.c_custkey
    JOIN part AS p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier AS supp
        ON lo.lo_suppkey = supp.s_suppkey
),
aggregated AS (
    SELECT
        supp_region,
        p_category,
        order_year,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supply_cost,
        COUNT(DISTINCT lo_orderkey) AS order_cnt,
        AVG(lo_discount) AS avg_discount
    FROM joined_data
    GROUP BY supp_region, p_category, order_year
)
SELECT
    supp_region,
    p_category,
    order_year,
    total_revenue,
    total_supply_cost,
    order_cnt,
    avg_discount,
    RANK() OVER (PARTITION BY supp_region, order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY supp_region, order_year, revenue_rank
LIMIT 50
