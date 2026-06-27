WITH order_detail AS (
    SELECT
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        p.p_category,
        p.p_brand1,
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        d.d_year,
        d.d_month
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE d.d_year = '1995'
)
SELECT
    d_year,
    p_category,
    customer_region,
    supplier_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue) - SUM(lo_supplycost) AS profit,
    AVG(lo_discount) AS avg_discount
FROM order_detail
GROUP BY d_year, p_category, customer_region, supplier_region
ORDER BY profit DESC
LIMIT 100
