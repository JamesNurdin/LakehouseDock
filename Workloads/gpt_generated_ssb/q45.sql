WITH filtered_orders AS (
    SELECT
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        cust.c_region,
        supp.s_region,
        part.p_category
    FROM lineorder lo
    JOIN dim_date order_date
        ON CAST(lo.lo_orderdate AS varchar) = order_date.d_datekey
    JOIN dim_date commit_date
        ON CAST(lo.lo_commitdate AS varchar) = commit_date.d_datekey
    JOIN customer cust
        ON lo.lo_custkey = cust.c_custkey
    JOIN part part
        ON lo.lo_partkey = part.p_partkey
    JOIN supplier supp
        ON lo.lo_suppkey = supp.s_suppkey
    WHERE order_date.d_year = '1995'
      AND commit_date.d_year = '1995'
      AND lo.lo_discount BETWEEN 5 AND 7
      AND lo.lo_orderpriority IN ('1-URGENT', '2-HIGH')
)
SELECT
    c_region,
    s_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM filtered_orders
GROUP BY c_region, s_region, p_category
ORDER BY total_revenue DESC
LIMIT 100
