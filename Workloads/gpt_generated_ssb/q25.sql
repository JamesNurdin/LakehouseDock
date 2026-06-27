WITH joined_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        d.d_year,
        d.d_date,
        p.p_category,
        s.s_region,
        c.c_region AS cust_region
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND p.p_category = 'MFGR#1'
),
aggregated AS (
    SELECT
        d_year AS year,
        s_region AS supplier_region,
        cust_region AS customer_region,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount
    FROM joined_data
    GROUP BY d_year, s_region, cust_region
)
SELECT
    year,
    supplier_region,
    customer_region,
    total_revenue,
    total_supplycost,
    total_profit,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY year, profit_rank
LIMIT 10
