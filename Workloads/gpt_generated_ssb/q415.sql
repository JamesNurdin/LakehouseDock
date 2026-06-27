WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        c.c_region AS c_region,
        c.c_nation AS c_nation,
        d_o.d_date AS order_date,
        d_o.d_year AS order_year,
        p.p_category AS p_category,
        p.p_brand1 AS p_brand1,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN dim_date d_o
        ON lo.lo_orderdate = CAST(d_o.d_datekey AS integer)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d_c
        ON lo.lo_commitdate = CAST(d_c.d_datekey AS integer)
    WHERE CAST(d_o.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
      AND p.p_category = 'MFGR#12'
)
SELECT
    order_year,
    c_region,
    supplier_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    SUM(lo_quantity) AS total_quantity
FROM order_info
GROUP BY order_year, c_region, supplier_region, p_category
ORDER BY total_revenue DESC
LIMIT 20
