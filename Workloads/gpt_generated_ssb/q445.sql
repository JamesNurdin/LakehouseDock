WITH agg AS (
    SELECT
        dim_date.d_year,
        supplier.s_region,
        part.p_category,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit
    FROM lineorder
    JOIN dim_date
        ON lineorder.lo_orderdate = CAST(dim_date.d_datekey AS integer)
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    WHERE lineorder.lo_discount < 5
      AND lineorder.lo_shipmode = 'AIR'
      AND dim_date.d_year = '1995'
    GROUP BY dim_date.d_year, supplier.s_region, part.p_category
),
ranked AS (
    SELECT
        d_year,
        s_region,
        p_category,
        total_revenue,
        total_profit,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS region_rank
    FROM agg
)
SELECT
    d_year,
    s_region,
    p_category,
    total_revenue,
    total_profit
FROM ranked
WHERE region_rank <= 5
ORDER BY d_year, total_profit DESC
