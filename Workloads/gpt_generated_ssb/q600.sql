WITH order_base AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_shipmode,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    WHERE d.d_year = '1995'
      AND lo.lo_shipmode = 'AIR'
)
SELECT
    c.c_region,
    s.s_region,
    d.d_year,
    p.p_brand1,
    SUM(ob.lo_revenue) AS total_revenue,
    AVG(ob.lo_discount) AS avg_discount,
    SUM(ob.lo_quantity) AS total_quantity,
    COUNT(DISTINCT ob.lo_orderkey) AS order_cnt
FROM order_base ob
JOIN customer c
    ON ob.lo_custkey = c.c_custkey
JOIN supplier s
    ON ob.lo_suppkey = s.s_suppkey
JOIN part p
    ON ob.lo_partkey = p.p_partkey
JOIN dim_date d
    ON ob.lo_orderdate = CAST(d.d_datekey AS integer)
WHERE p.p_category = 'MFGR#1'
GROUP BY
    c.c_region,
    s.s_region,
    d.d_year,
    p.p_brand1
ORDER BY total_revenue DESC
LIMIT 20
