WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        p.p_category,
        s.s_region,
        d.d_date
    FROM
        lineorder lo
        JOIN dim_date d
            ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
        JOIN part p
            ON lo.lo_partkey = p.p_partkey
        JOIN supplier s
            ON lo.lo_suppkey = s.s_suppkey
    WHERE
        CAST(d.d_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
)
SELECT
    p_category,
    s_region,
    COUNT(DISTINCT lo_orderkey) AS order_cnt,
    SUM(lo_extendedprice) AS total_extendedprice,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount
FROM
    filtered_orders
GROUP BY
    p_category,
    s_region
ORDER BY
    total_profit DESC
LIMIT 10
