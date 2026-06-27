/*
  SSB analytical query – revenue and profit trends by year and customer region.
  Joins lineorder with the date dimension (order date), customer, part and supplier
  using only the allowed join keys.  The query first aggregates revenue per year
  and region, then computes a running total of revenue for each region.
*/
WITH orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_extendedprice,
        lo.lo_tax,
        d.d_year,
        c.c_region,
        p.p_category,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey   -- lineorder.lo_orderdate = dim_date.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey                     -- lineorder.lo_custkey = customer.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey                     -- lineorder.lo_partkey = part.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey                     -- lineorder.lo_suppkey = supplier.s_suppkey
    WHERE d.d_year BETWEEN '1993' AND '1995'
),
yearly_region_rev AS (
    SELECT
        d_year,
        c_region,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY d_year, c_region
)
SELECT
    d_year,
    c_region,
    total_revenue,
    total_profit,
    avg_discount,
    order_count,
    SUM(total_revenue) OVER (
        PARTITION BY c_region
        ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue_by_region
FROM yearly_region_rev
ORDER BY c_region, d_year
