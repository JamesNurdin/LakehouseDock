WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_supplycost,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    oc.order_year,
    s.s_region,
    SUM(oc.lo_revenue) AS total_revenue,
    SUM(oc.lo_quantity) AS total_quantity,
    AVG(oc.lo_discount) AS avg_discount,
    SUM(oc.lo_revenue - oc.lo_supplycost) AS total_profit,
    COUNT(DISTINCT oc.lo_orderkey) AS distinct_orders
FROM order_commit oc
JOIN supplier s
    ON oc.lo_suppkey = s.s_suppkey
WHERE oc.order_year = '1997'
  AND oc.commit_year = '1997'
GROUP BY oc.order_year, s.s_region
ORDER BY total_revenue DESC
LIMIT 10
