WITH yearly_category_stats AS (
    SELECT
        dim_date.d_year,
        part.p_category,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
        AVG(lineorder.lo_discount) AS avg_discount,
        SUM(lineorder.lo_quantity) AS total_quantity
    FROM lineorder
    JOIN dim_date
        ON lineorder.lo_orderdate = CAST(dim_date.d_datekey AS integer)
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    GROUP BY dim_date.d_year, part.p_category
)
SELECT
    d_year,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    total_quantity
FROM (
    SELECT
        d_year,
        p_category,
        total_revenue,
        total_profit,
        avg_discount,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_revenue DESC) AS rn
    FROM yearly_category_stats
) ranked
WHERE rn <= 5
ORDER BY d_year, total_revenue DESC
