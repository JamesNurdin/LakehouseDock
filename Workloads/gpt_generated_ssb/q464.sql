WITH yearly_supplier_customer AS (
    SELECT
        dim_date.d_year,
        supplier.s_region,
        customer.c_mktsegment,
        sum(lineorder.lo_revenue) AS total_revenue,
        sum(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
        avg(lineorder.lo_discount) AS avg_discount
    FROM lineorder
    JOIN dim_date
      ON CAST(lineorder.lo_orderdate AS VARCHAR) = dim_date.d_datekey
    JOIN supplier
      ON lineorder.lo_suppkey = supplier.s_suppkey
    JOIN customer
      ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
      ON lineorder.lo_partkey = part.p_partkey
    WHERE dim_date.d_year BETWEEN '1992' AND '1997'
      AND part.p_category = 'MFGR#1'
      AND customer.c_mktsegment = 'AUTOMOBILE'
    GROUP BY dim_date.d_year, supplier.s_region, customer.c_mktsegment
)
SELECT
    d_year,
    s_region,
    c_mktsegment,
    total_revenue,
    total_profit,
    avg_discount,
    rank() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM yearly_supplier_customer
ORDER BY d_year, profit_rank
