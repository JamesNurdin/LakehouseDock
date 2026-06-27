WITH order_dates AS (
    SELECT d_datekey, d_year, d_month, d_date
    FROM dim_date
    WHERE d_year = '1997'
),
commit_dates AS (
    SELECT d_datekey, d_weekdayfl
    FROM dim_date
    WHERE d_weekdayfl = 'Y'
)
SELECT
    od.d_year,
    od.d_month,
    cd.d_weekdayfl,
    COUNT(DISTINCT lo.lo_orderkey) AS num_orders,
    SUM(lo.lo_quantity) AS total_quantity,
    SUM(lo.lo_extendedprice) AS total_extended_price,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    (SUM(lo.lo_revenue - lo.lo_supplycost) / NULLIF(SUM(lo.lo_revenue), 0)) AS profit_margin,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN order_dates od
    ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
JOIN commit_dates cd
    ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
GROUP BY od.d_year, od.d_month, cd.d_weekdayfl
ORDER BY od.d_year, od.d_month, cd.d_weekdayfl
