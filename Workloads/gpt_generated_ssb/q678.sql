SELECT
    d.d_year,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM
    lineorder lo
JOIN dim_date d
    ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
JOIN part p
    ON lo.lo_partkey = p.p_partkey
WHERE
    d.d_year = '1997'
GROUP BY
    d.d_year,
    p.p_category
ORDER BY
    total_revenue DESC
