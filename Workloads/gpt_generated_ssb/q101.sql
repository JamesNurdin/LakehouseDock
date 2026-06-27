WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_shipmode,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    WHERE d.d_year = '1995'
),
aggregated AS (
    SELECT
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category AS product_category,
        SUM(lo_extendedprice) AS total_extendedprice,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders
    FROM filtered_orders fo
    JOIN customer c ON fo.lo_custkey = c.c_custkey
    JOIN supplier s ON fo.lo_suppkey = s.s_suppkey
    JOIN part p ON fo.lo_partkey = p.p_partkey
    GROUP BY
        c.c_region,
        s.s_region,
        p.p_category
)
SELECT
    customer_region,
    supplier_region,
    product_category,
    total_extendedprice,
    total_revenue,
    total_profit,
    avg_discount,
    distinct_orders,
    RANK() OVER (PARTITION BY customer_region ORDER BY total_profit DESC) AS profit_rank_by_customer_region
FROM aggregated
ORDER BY total_profit DESC
LIMIT 20
