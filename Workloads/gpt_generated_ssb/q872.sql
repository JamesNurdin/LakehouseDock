WITH filtered_lo AS (
    SELECT
        lo_orderkey,
        lo_orderdate,
        lo_partkey,
        lo_suppkey,
        lo_quantity,
        lo_revenue,
        lo_supplycost,
        lo_discount
    FROM lineorder
    WHERE lo_discount > 5
      AND lo_orderpriority IN ('1-URGENT', '2-HIGH')
      AND lo_shipmode = 'AIR'
),
joined AS (
    SELECT
        fl.lo_orderkey,
        fl.lo_quantity,
        fl.lo_revenue,
        fl.lo_supplycost,
        fl.lo_discount,
        od.d_year,
        p.p_category,
        s.s_region
    FROM filtered_lo AS fl
    JOIN dim_date AS od
        ON CAST(fl.lo_orderdate AS varchar) = od.d_datekey
    JOIN part AS p
        ON p.p_partkey = fl.lo_partkey
    JOIN supplier AS s
        ON s.s_suppkey = fl.lo_suppkey
)
SELECT
    d_year AS order_year,
    p_category AS part_category,
    s_region AS supplier_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM joined
GROUP BY d_year, p_category, s_region
ORDER BY total_revenue DESC
LIMIT 100
