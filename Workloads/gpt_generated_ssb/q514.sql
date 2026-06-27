/*
  Revenue, supply‑cost and profit broken down by customer region, supplier region,
  part category and order year (1995). The query joins the lineorder fact table
  to all dimension tables using the only permitted join keys, filters on the
  order‑date dimension, and aggregates the monetary measures.
*/
WITH joined_orders AS (
    SELECT
        c.c_region   AS cust_region,
        s.s_region   AS supp_region,
        p.p_category,
        d_o.d_year,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d_o
        ON CAST(lo.lo_orderdate AS varchar) = d_o.d_datekey
    JOIN dim_date d_c
        ON CAST(lo.lo_commitdate AS varchar) = d_c.d_datekey
    WHERE d_o.d_year = '1995'
)
SELECT
    cust_region,
    supp_region,
    p_category,
    d_year,
    SUM(lo_quantity)                     AS total_quantity,
    SUM(lo_revenue)                      AS total_revenue,
    SUM(lo_supplycost)                   AS total_supplycost,
    SUM(lo_revenue - lo_supplycost)      AS total_profit,
    AVG(lo_discount)                     AS avg_discount
FROM joined_orders
GROUP BY cust_region, supp_region, p_category, d_year
ORDER BY total_profit DESC
LIMIT 10
