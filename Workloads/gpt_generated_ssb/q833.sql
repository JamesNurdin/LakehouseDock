WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        cust.c_region,
        cust.c_mktsegment,
        part.p_category,
        supp.s_region AS supplier_region,
        dim.d_year
    FROM lineorder lo
    JOIN dim_date dim ON lo.lo_orderdate = CAST(dim.d_datekey AS INTEGER)
    JOIN customer cust ON lo.lo_custkey = cust.c_custkey
    JOIN part part ON lo.lo_partkey = part.p_partkey
    JOIN supplier supp ON lo.lo_suppkey = supp.s_suppkey
    WHERE dim.d_year = '1995'
      AND cust.c_mktsegment = 'AUTOMOBILE'
)
SELECT
    d_year,
    supplier_region,
    p_category,
    sum(lo_revenue) AS total_revenue,
    sum(lo_revenue - lo_supplycost) AS total_profit,
    sum(lo_quantity) AS total_quantity,
    sum(lo_extendedprice) AS total_extendedprice,
    sum(lo_extendedprice * (1 - lo_discount / 100.0)) AS net_sales,
    cast(sum(lo_revenue - lo_supplycost) AS double) / nullif(sum(lo_revenue), 0) AS profit_margin
FROM filtered_orders
GROUP BY d_year, supplier_region, p_category
ORDER BY total_revenue DESC
LIMIT 20
