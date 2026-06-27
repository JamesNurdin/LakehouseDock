WITH profit_by_supplier AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_revenue,
        s.s_nation AS s_nation,
        p.p_brand1 AS p_brand1,
        d.d_year AS order_year
    FROM lineorder lo
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    WHERE p.p_brand1 = 'Brand#45'
      AND d.d_year = '1997'
)
SELECT
    order_year,
    s_nation,
    p_brand1,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice) AS total_extendedprice,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_extendedprice - lo_supplycost) AS total_gross_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM profit_by_supplier
GROUP BY order_year, s_nation, p_brand1
ORDER BY total_gross_profit DESC
LIMIT 20
