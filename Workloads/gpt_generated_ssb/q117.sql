WITH filtered_orders AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_quantity,
        lo_tax,
        lo_commitdate,
        d_year AS order_year
    FROM lineorder
    JOIN dim_date
        ON CAST(lineorder.lo_orderdate AS VARCHAR) = dim_date.d_datekey
    WHERE CAST(dim_date.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
aggregated AS (
    SELECT
        s.s_region AS supplier_region,
        p.p_category AS part_category,
        fo.order_year,
        SUM(fo.lo_revenue) AS total_revenue,
        SUM(fo.lo_supplycost) AS total_supplycost,
        SUM(fo.lo_revenue) - SUM(fo.lo_supplycost) AS profit,
        AVG(fo.lo_discount) AS avg_discount,
        COUNT(DISTINCT fo.lo_orderkey) AS order_count
    FROM filtered_orders fo
    JOIN customer c
        ON fo.lo_custkey = c.c_custkey
    JOIN part p
        ON fo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON fo.lo_suppkey = s.s_suppkey
    WHERE c.c_region = 'ASIA'
    GROUP BY s.s_region, p.p_category, fo.order_year
)
SELECT
    supplier_region,
    part_category,
    order_year,
    total_revenue,
    total_supplycost,
    profit,
    avg_discount,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY supplier_region, order_year ORDER BY profit DESC) AS profit_rank
FROM aggregated
WHERE profit > 0
ORDER BY supplier_region, order_year, profit_rank
LIMIT 50
