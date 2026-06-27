WITH profit_by_year_supplier AS (
    SELECT
        od.d_year,
        s.s_region,
        SUM(lo_extendedprice * (1 - lo_discount / 100.0) - lo_supplycost * lo_quantity) AS profit,
        SUM(lo_extendedprice * (1 - lo_discount / 100.0)) AS revenue,
        SUM(lo_quantity) AS total_quantity,
        AVG(lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date od ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE DATE(od.d_date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND p.p_category = 'MFGR#1'
      AND lo.lo_shipmode = 'AIR'
    GROUP BY od.d_year, s.s_region
)
SELECT
    d_year,
    s_region,
    profit,
    revenue,
    total_quantity,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY profit DESC) AS profit_rank
FROM profit_by_year_supplier
ORDER BY d_year, profit_rank
