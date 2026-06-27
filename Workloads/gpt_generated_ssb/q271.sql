WITH order_info AS (
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
        lo.lo_quantity,
        lo.lo_tax,
        lo.lo_commitdate,
        lo.lo_shipmode,
        c.c_region,
        d.d_year,
        p.p_category,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN dim_date d ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
),
agg AS (
    SELECT
        c_region,
        supplier_region,
        d_year,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        COUNT(DISTINCT lo_orderkey) AS order_count
    FROM order_info
    GROUP BY c_region, supplier_region, d_year, p_category
)
SELECT
    c_region,
    supplier_region,
    d_year,
    p_category,
    total_revenue,
    total_profit,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY c_region, d_year ORDER BY total_profit DESC) AS profit_rank_within_region_year
FROM agg
ORDER BY total_profit DESC
LIMIT 20
