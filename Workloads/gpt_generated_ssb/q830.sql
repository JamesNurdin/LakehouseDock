WITH order_commit AS (
    SELECT
        lineorder.lo_orderkey,
        lineorder.lo_partkey,
        lineorder.lo_revenue,
        lineorder.lo_quantity,
        lineorder.lo_discount,
        od.d_year AS order_year,
        date_diff('day', CAST(cd.d_date AS date), CAST(od.d_date AS date)) AS days_to_commit,
        part.p_category
    FROM lineorder
    JOIN dim_date AS od
        ON lineorder.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date AS cd
        ON lineorder.lo_commitdate = CAST(cd.d_datekey AS integer)
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
)
SELECT
    order_year,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    AVG(days_to_commit) AS avg_days_to_commit,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount
FROM order_commit
WHERE order_year IN ('1995', '1996', '1997')
GROUP BY order_year, p_category
ORDER BY order_year, total_revenue DESC
