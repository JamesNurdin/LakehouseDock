WITH order_dates AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_orderdate,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON cast(lo.lo_orderdate AS varchar) = d.d_datekey
    WHERE d.d_date >= '1995-01-01'
      AND d.d_date <= '1995-12-31'
)
SELECT
    s.s_region,
    p.p_category,
    sum(od.lo_revenue) AS total_revenue,
    avg(od.lo_discount) AS avg_discount
FROM order_dates od
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, p.p_category
ORDER BY total_revenue DESC
