WITH aggregated AS (
    SELECT
        d.d_year AS order_year,
        c.c_region,
        p.p_category,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS total_net_sales,
        SUM(lo.lo_extendedprice - lo.lo_supplycost) AS total_profit
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1998-12-31'
    GROUP BY d.d_year, c.c_region, p.p_category
)
SELECT
    order_year,
    c_region,
    p_category,
    total_net_sales,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY order_year, c_region ORDER BY total_profit DESC) AS category_profit_rank
FROM aggregated
ORDER BY order_year, c_region, category_profit_rank
