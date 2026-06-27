WITH order_details AS (
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
        d_o.d_year AS order_year,
        d_o.d_date AS order_date,
        d_c.d_year AS commit_year,
        d_c.d_date AS commit_date,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        c.c_region AS customer_region
    FROM lineorder lo
    JOIN dim_date d_o
      ON CAST(d_o.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date d_c
      ON CAST(d_c.d_datekey AS INTEGER) = lo.lo_commitdate
    JOIN part p
      ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
      ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
      ON lo.lo_custkey = c.c_custkey
    WHERE d_o.d_year = '1995'
      AND s.s_region = 'ASIA'
),
aggregated AS (
    SELECT
        order_year,
        customer_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        COUNT(*) AS order_count
    FROM order_details
    GROUP BY order_year, customer_region, p_category
)
SELECT
    order_year,
    customer_region,
    p_category,
    total_revenue,
    total_supplycost,
    total_profit,
    order_count,
    RANK() OVER (PARTITION BY order_year ORDER BY total_profit DESC) AS profit_rank_by_category
FROM aggregated
ORDER BY total_revenue DESC
LIMIT 50
