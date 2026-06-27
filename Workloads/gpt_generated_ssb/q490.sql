WITH revenue_by_order AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) AS revenue
    FROM lineorder lo
)
SELECT
    s.s_region,
    p.p_category,
    d_order.d_yearmonth,
    SUM(r.revenue) AS total_revenue,
    AVG(r.revenue) AS avg_revenue,
    AVG(date_diff('day', CAST(d_order.d_date AS date), CAST(d_commit.d_date AS date))) AS avg_shipping_delay,
    COUNT(DISTINCT r.lo_orderkey) AS distinct_orders,
    COUNT(*) AS line_items
FROM revenue_by_order r
JOIN dim_date d_order
  ON CAST(d_order.d_datekey AS integer) = r.lo_orderdate
JOIN dim_date d_commit
  ON CAST(d_commit.d_datekey AS integer) = r.lo_commitdate
JOIN customer c
  ON r.lo_custkey = c.c_custkey
JOIN part p
  ON r.lo_partkey = p.p_partkey
JOIN supplier s
  ON r.lo_suppkey = s.s_suppkey
WHERE d_order.d_year = '1995'
GROUP BY
    s.s_region,
    p.p_category,
    d_order.d_yearmonth
ORDER BY total_revenue DESC
LIMIT 20
