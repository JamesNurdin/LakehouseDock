WITH enriched_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        c.c_region AS cust_region,
        s.s_region AS supp_region,
        p.p_category,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS INTEGER) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year = '1993'
      AND c.c_region = 'AMERICA'
),
aggregated AS (
    SELECT
        order_year,
        order_month,
        cust_region,
        supp_region,
        p_category,
        SUM(lo_extendedprice * (1 - lo_discount / 100.0)) AS net_sales,
        SUM(lo_revenue - lo_supplycost) AS profit,
        COUNT(DISTINCT lo_orderkey) AS num_orders
    FROM enriched_orders
    GROUP BY
        order_year,
        order_month,
        cust_region,
        supp_region,
        p_category
)
SELECT
    order_year,
    order_month,
    cust_region,
    supp_region,
    p_category,
    net_sales,
    profit,
    num_orders,
    RANK() OVER (PARTITION BY order_year, order_month ORDER BY profit DESC) AS profit_rank
FROM aggregated
ORDER BY
    order_year,
    order_month,
    profit_rank
