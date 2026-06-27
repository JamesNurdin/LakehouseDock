WITH base AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        od.d_year,
        s.s_region,
        p.p_category,
        c.c_region
    FROM
        lineorder lo
    JOIN
        dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN
        supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN
        part p ON lo.lo_partkey = p.p_partkey
    JOIN
        customer c ON lo.lo_custkey = c.c_custkey
    WHERE
        od.d_year BETWEEN '1992' AND '1997'
        AND lo.lo_discount BETWEEN 1 AND 3
        AND lo.lo_quantity < 25
        AND p.p_category = 'MFGR#12'
        AND c.c_region = 'AMERICA'
)
SELECT
    d_year,
    s_region,
    p_category,
    c_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS order_cnt
FROM
    base
GROUP BY
    d_year,
    s_region,
    p_category,
    c_region
ORDER BY
    d_year,
    s_region,
    p_category,
    c_region
