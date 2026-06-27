/*
  Supplier profit share by region and year (1995‑1997)
  The query:
    • Joins lineorder to dim_date (order date), customer and supplier using the allowed join keys.
    • Filters orders to the date range 1995‑01‑01 … 1997‑12‑31 via dim_date.d_date.
    • Calculates total profit per region‑year and per supplier‑region‑year.
    • Computes each supplier's profit share of its region‑year total.
    • Ranks suppliers within each region‑year by profit.
*/
WITH region_year_profit AS (
    SELECT
        d.d_year,
        c.c_region,
        sum(lo.lo_revenue - lo.lo_supplycost) AS region_profit
    FROM lineorder lo
    JOIN dim_date d
        ON cast(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE cast(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
    GROUP BY d.d_year, c.c_region
),
supplier_profit AS (
    SELECT
        d.d_year,
        c.c_region,
        s.s_name,
        sum(lo.lo_revenue - lo.lo_supplycost) AS supplier_profit
    FROM lineorder lo
    JOIN dim_date d
        ON cast(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE cast(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
    GROUP BY d.d_year, c.c_region, s.s_name
)
SELECT
    sp.d_year,
    sp.c_region,
    sp.s_name,
    sp.supplier_profit,
    rp.region_profit,
    (sp.supplier_profit / nullif(rp.region_profit, 0)) * 100.0 AS profit_share_percent,
    rank() OVER (PARTITION BY sp.d_year, sp.c_region ORDER BY sp.supplier_profit DESC) AS supplier_rank
FROM supplier_profit sp
JOIN region_year_profit rp
    ON sp.d_year = rp.d_year
   AND sp.c_region = rp.c_region
ORDER BY sp.d_year, sp.c_region, supplier_rank
