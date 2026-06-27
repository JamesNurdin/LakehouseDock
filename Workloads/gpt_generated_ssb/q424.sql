WITH filtered_orders AS (
    SELECT
        lo.lo_shipmode,
        lo.lo_revenue,
        lo.lo_quantity,
        lo.lo_discount,
        od.d_year,
        od.d_month
    FROM lineorder lo
    JOIN dim_date od
      ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd
      ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
    WHERE od.d_year = '1995'
      AND cd.d_holidayfl = 'Y'
)
SELECT
    d_year,
    d_month,
    lo_shipmode,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount
FROM filtered_orders
GROUP BY d_year, d_month, lo_shipmode
ORDER BY total_revenue DESC
