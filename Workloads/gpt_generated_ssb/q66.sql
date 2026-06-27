WITH order_dim AS (
    SELECT
        CAST(d_datekey AS integer) AS date_key,
        d_date,
        d_year
    FROM dim_date
)
SELECT
    od.d_year                     AS order_year,
    c.c_region                    AS customer_region,
    p.p_category                  AS product_category,
    s.s_region                    AS supplier_region,
    SUM(lo.lo_revenue)            AS total_revenue,
    SUM(lo.lo_quantity)           AS total_quantity,
    AVG(lo.lo_discount)           AS avg_discount,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN order_dim od
    ON lo.lo_orderdate = od.date_key
JOIN dim_date commit_dt
    ON lo.lo_commitdate = CAST(commit_dt.d_datekey AS integer)
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE CAST(od.d_date AS date) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY od.d_year, c.c_region, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 20
