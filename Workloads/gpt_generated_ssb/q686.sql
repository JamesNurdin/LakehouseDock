WITH joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d_order.d_year AS order_year,
        d_commit.d_month AS commit_month
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
    WHERE d_order.d_year = '1995'
      AND d_commit.d_month = 'December'
)
SELECT
    order_year,
    commit_month,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    SUM(lo_quantity) AS total_quantity,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue) - SUM(lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount
FROM joined
GROUP BY order_year, commit_month
ORDER BY order_year, commit_month
