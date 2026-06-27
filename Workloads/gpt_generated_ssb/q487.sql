WITH profit_by_regions AS (
    SELECT
        d.d_year,
        c.c_region AS cust_region,
        s.s_region AS supp_region,
        SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS profit,
        SUM(lo.lo_extendedprice) AS total_extended_price,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date d ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category = 'MFGR#12'
    GROUP BY d.d_year, c.c_region, s.s_region
)
SELECT
    d_year,
    cust_region,
    supp_region,
    profit,
    total_extended_price,
    avg_discount,
    RANK() OVER (PARTITION BY d_year ORDER BY profit DESC) AS profit_rank
FROM profit_by_regions
ORDER BY d_year, profit_rank
LIMIT 50
