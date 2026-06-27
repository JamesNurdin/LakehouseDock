WITH revenue_by_category AS (
    SELECT 
        ord_date.d_year AS year,
        s.s_region AS supplier_region,
        p.p_category AS product_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
    FROM lineorder lo
    JOIN dim_date ord_date 
        ON CAST(lo.lo_orderdate AS varchar) = ord_date.d_datekey
    JOIN customer c 
        ON lo.lo_custkey = c.c_custkey
    JOIN part p 
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s 
        ON lo.lo_suppkey = s.s_suppkey
    WHERE ord_date.d_year = '1995'
      AND lo.lo_shipmode = 'AIR'
      AND lo.lo_discount BETWEEN 5 AND 10
    GROUP BY ord_date.d_year, s.s_region, p.p_category
)
SELECT 
    year,
    supplier_region,
    product_category,
    total_revenue,
    total_supply_cost,
    total_profit,
    (total_profit * 1.0 / NULLIF(total_revenue, 0)) * 100 AS profit_margin_percent,
    RANK() OVER (PARTITION BY year, supplier_region ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_category
ORDER BY year, supplier_region, revenue_rank
