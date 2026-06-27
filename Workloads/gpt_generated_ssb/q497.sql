WITH order_dt AS (
    SELECT
        d_datekey,
        d_year,
        d_date
    FROM dim_date
    WHERE d_year IN ('1995', '1996')
)
SELECT
    order_dt.d_year,
    cust.c_region,
    supp.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    SUM(lo.lo_quantity) AS total_quantity,
    SUM(lo.lo_revenue) / NULLIF(SUM(lo.lo_quantity), 0) AS revenue_per_quantity,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN order_dt
    ON CAST(order_dt.d_datekey AS integer) = lo.lo_orderdate
JOIN customer cust
    ON lo.lo_custkey = cust.c_custkey
JOIN supplier supp
    ON lo.lo_suppkey = supp.s_suppkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
GROUP BY
    order_dt.d_year,
    cust.c_region,
    supp.s_region,
    p.p_category
ORDER BY total_revenue DESC
