WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_quantity,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1,
        d.d_year,
        d.d_month,
        d.d_yearmonth,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
),
aggregated AS (
    SELECT
        d_year,
        d_month,
        c_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost - lo_tax) AS total_profit,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders
    FROM order_details
    WHERE d_year BETWEEN '1995' AND '1997'
    GROUP BY d_year, d_month, c_region, p_category
)
SELECT
    d_year,
    d_month,
    c_region,
    p_category,
    total_revenue,
    total_profit,
    distinct_orders,
    RANK() OVER (PARTITION BY d_year, d_month ORDER BY total_revenue DESC) AS revenue_rank_by_region_month
FROM aggregated
ORDER BY d_year, d_month, revenue_rank_by_region_month
