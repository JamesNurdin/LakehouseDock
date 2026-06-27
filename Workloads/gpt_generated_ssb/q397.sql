WITH joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_orderdate,
        lo.lo_commitdate,
        c.c_region AS customer_region,
        c.c_nation AS customer_nation,
        c.c_mktsegment AS customer_market_segment,
        p.p_category,
        p.p_brand1,
        p.p_color,
        p.p_type,
        p.p_size,
        p.p_container,
        s.s_region AS supplier_region,
        s.s_nation AS supplier_nation,
        od.d_year AS order_year,
        od.d_month AS order_month,
        od.d_date AS order_date,
        cm.d_year AS commit_year,
        cm.d_month AS commit_month,
        cm.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN dim_date cm
        ON lo.lo_commitdate = CAST(cm.d_datekey AS INTEGER)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    supplier_region,
    p_category,
    order_year,
    order_month,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    SUM(lo_revenue - lo_supplycost) / NULLIF(SUM(lo_revenue), 0) AS profit_margin
FROM joined
GROUP BY supplier_region, p_category, order_year, order_month
ORDER BY total_revenue DESC
LIMIT 100
