SELECT
    d.d_year,
    c.c_region,
    p.p_category,
    sum(lo.lo_revenue) AS total_revenue,
    sum(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    count(*) AS order_count
FROM lineorder lo
JOIN dim_date d
    ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE d.d_year BETWEEN '1992' AND '1997'
GROUP BY
    d.d_year,
    c.c_region,
    p.p_category
ORDER BY
    d.d_year,
    c.c_region,
    p.p_category
