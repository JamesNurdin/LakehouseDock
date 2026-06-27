/*
  Revenue, profit and discount analysis per year, customer region, product category, and supplier.
  Shows the top suppliers by profit for each year within the selected period.
*/
WITH base AS (
    SELECT
        d.d_year,
        c.c_region AS cust_region,
        p.p_category,
        s.s_name,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_discount
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year BETWEEN '1993' AND '1995'
      AND p.p_category = 'MFGR#12'
      AND c.c_region = 'AMERICA'
),
agg AS (
    SELECT
        d_year,
        cust_region,
        p_category,
        s_name,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost - lo_tax) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM base
    GROUP BY d_year, cust_region, p_category, s_name
)
SELECT
    d_year,
    cust_region,
    p_category,
    s_name,
    total_revenue,
    total_profit,
    avg_discount,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
WHERE total_profit > 0
ORDER BY d_year, profit_rank
LIMIT 20
