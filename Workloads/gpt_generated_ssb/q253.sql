/*
  Revenue and quantity per supplier for MFGR#1 parts in 1997, ranked by revenue.
  This query joins the SSB tables using only the allowed join keys, filters by year
  and part category, aggregates per supplier and year, and then ranks the suppliers.
*/
WITH yearly_supplier_revenue AS (
    SELECT
        dim_date.d_year AS year,
        supplier.s_name AS supplier_name,
        SUM(lineorder.lo_revenue) AS revenue,
        SUM(lineorder.lo_quantity) AS quantity
    FROM lineorder
    JOIN dim_date
        ON lineorder.lo_orderdate = CAST(dim_date.d_datekey AS integer)
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    WHERE dim_date.d_year = '1997'
      AND part.p_category = 'MFGR#1'
    GROUP BY dim_date.d_year, supplier.s_name
)
SELECT
    year,
    supplier_name,
    revenue,
    quantity,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM yearly_supplier_revenue
ORDER BY revenue_rank
LIMIT 5
