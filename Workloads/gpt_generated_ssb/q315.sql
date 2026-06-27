/*
  Analytical query: total revenue, profit and distinct order count per year‑month for orders
  placed and committed in 1994‑1995. The query joins the lineorder fact table to the
  dim_date dimension twice (once for the order date and once for the commit date),
  filters on the year, aggregates the financial metrics, and orders the result by
  year and month.
*/
WITH order_fact AS (
    SELECT
        lo_orderkey,
        lo_orderdate,
        lo_commitdate,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_discount,
        lo_orderpriority,
        lo_shipmode
    FROM lineorder
),
order_date_dim AS (
    SELECT
        d_datekey,
        d_year,
        d_month,
        d_yearmonth,
        d_date
    FROM dim_date
    WHERE d_year IN ('1994', '1995')
),
commit_date_dim AS (
    SELECT
        d_datekey,
        d_year AS commit_year,
        d_month AS commit_month,
        d_date AS commit_date
    FROM dim_date
    WHERE d_year IN ('1994', '1995')
)
SELECT
    od.d_year,
    od.d_month,
    od.d_yearmonth,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_supplycost) AS total_supplycost,
    SUM(o.lo_tax) AS total_tax,
    SUM(o.lo_discount) AS total_discount,
    SUM(o.lo_revenue - o.lo_supplycost - o.lo_tax - o.lo_discount) AS total_profit,
    COUNT(DISTINCT o.lo_orderkey) AS distinct_orders
FROM order_fact o
JOIN order_date_dim od
    ON CAST(o.lo_orderdate AS varchar) = od.d_datekey
JOIN commit_date_dim cd
    ON CAST(o.lo_commitdate AS varchar) = cd.d_datekey
WHERE od.d_year IN ('1994', '1995')
  AND cd.commit_year IN ('1994', '1995')
GROUP BY od.d_year, od.d_month, od.d_yearmonth
ORDER BY od.d_year, od.d_month
