WITH orders_by_month AS (
    SELECT
        dd.d_year,
        dd.d_month,
        sum(lo.lo_revenue) AS total_revenue,
        sum(lo.lo_extendedprice) AS total_extendedprice,
        sum(lo.lo_quantity) AS total_quantity,
        avg(lo.lo_discount) AS avg_discount,
        count(distinct lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN dim_date dd
      ON cast(dd.d_datekey AS integer) = lo.lo_orderdate
    WHERE cast(dd.d_date AS date) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY dd.d_year, dd.d_month
),
cumulative AS (
    SELECT
        d_year,
        d_month,
        total_revenue,
        total_extendedprice,
        total_quantity,
        avg_discount,
        order_count,
        sum(total_revenue) OVER (ORDER BY d_year, d_month) AS cumulative_revenue
    FROM orders_by_month
)
SELECT
    d_year,
    d_month,
    total_revenue,
    total_extendedprice,
    total_quantity,
    avg_discount,
    order_count,
    cumulative_revenue
FROM cumulative
ORDER BY total_revenue DESC
