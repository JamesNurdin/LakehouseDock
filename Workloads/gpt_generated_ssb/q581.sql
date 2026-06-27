WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        d.d_year,
        c.c_region,
        s.s_region
    FROM lineorder AS lo
    JOIN dim_date AS d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer AS c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier AS s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part AS p
        ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category = 'MFGR#1'
      AND s.s_region = 'ASIA'
      AND d.d_year BETWEEN '1995' AND '1997'
)
SELECT
    d_year,
    c_region,
    s_region,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM order_details
GROUP BY d_year, c_region, s_region
ORDER BY d_year, total_revenue DESC
