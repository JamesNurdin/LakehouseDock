WITH order_details AS (
    SELECT
        l.lo_extendedprice,
        l.lo_supplycost,
        l.lo_quantity,
        l.lo_discount,
        d.d_year,
        d.d_month,
        s.s_region,
        p.p_category
    FROM lineorder AS l
    JOIN dim_date AS d
        ON l.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN supplier AS s
        ON l.lo_suppkey = s.s_suppkey
    JOIN part AS p
        ON l.lo_partkey = p.p_partkey
    JOIN customer AS c
        ON l.lo_custkey = c.c_custkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    d_year,
    d_month,
    s_region,
    p_category,
    sum(lo_extendedprice) AS total_revenue,
    sum(lo_extendedprice - lo_supplycost) AS total_profit,
    sum(lo_quantity) AS total_quantity,
    avg(lo_discount) AS avg_discount
FROM order_details
GROUP BY d_year, d_month, s_region, p_category
ORDER BY d_year, d_month, s_region, p_category
