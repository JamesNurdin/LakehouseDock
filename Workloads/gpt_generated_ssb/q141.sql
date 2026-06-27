WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_shipmode,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_orderdate,
        d.d_year,
        d.d_month,
        d.d_yearmonth
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE d.d_year = '1997'
      AND lo.lo_discount > 0
),
monthly_profit AS (
    SELECT
        d_year,
        d_month,
        d_yearmonth,
        lo_shipmode,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_revenue) - SUM(lo_supplycost) AS profit,
        COUNT(DISTINCT lo_orderkey) AS order_cnt
    FROM order_dates
    GROUP BY d_year, d_month, d_yearmonth, lo_shipmode
)
SELECT
    mp.d_year,
    mp.d_month,
    mp.d_yearmonth,
    mp.lo_shipmode,
    mp.total_revenue,
    mp.total_supplycost,
    mp.profit,
    mp.order_cnt,
    RANK() OVER (PARTITION BY mp.d_year, mp.d_month ORDER BY mp.profit DESC) AS profit_rank
FROM monthly_profit mp
ORDER BY mp.d_year, mp.d_month, profit_rank
