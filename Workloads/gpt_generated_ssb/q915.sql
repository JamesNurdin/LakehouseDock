WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_quantity,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        c.c_region AS cust_region,
        c.c_nation AS cust_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supp_region,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d_order ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
    WHERE p.p_category = 'MFGR#12'
      AND d_order.d_year = '1995'
),
revenue_by_region AS (
    SELECT
        cust_region,
        order_year,
        SUM(lo_revenue) AS total_revenue,
        AVG(lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM order_details
    GROUP BY cust_region, order_year
)
SELECT
    cust_region,
    order_year,
    total_revenue,
    avg_discount,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS region_rank
FROM revenue_by_region
ORDER BY order_year, region_rank
