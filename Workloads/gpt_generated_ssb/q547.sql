/*
   Top‑5 customers by total revenue within each region.
   Uses only the selected tables (customer, lineorder) and the allowed join condition.
*/
WITH customer_revenue AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_region,
        c.c_mktsegment,
        sum(l.lo_revenue) AS total_revenue,
        sum(l.lo_quantity) AS total_quantity,
        avg(l.lo_discount) AS avg_discount
    FROM
        lineorder l
    JOIN
        customer c
        ON l.lo_custkey = c.c_custkey
    GROUP BY
        c.c_custkey,
        c.c_name,
        c.c_region,
        c.c_mktsegment
),
ranked_customers AS (
    SELECT
        cr.c_custkey,
        cr.c_name,
        cr.c_region,
        cr.c_mktsegment,
        cr.total_revenue,
        cr.total_quantity,
        cr.avg_discount,
        row_number() OVER (PARTITION BY cr.c_region ORDER BY cr.total_revenue DESC) AS region_rank
    FROM
        customer_revenue cr
)
SELECT
    rc.c_custkey,
    rc.c_name,
    rc.c_region,
    rc.c_mktsegment,
    rc.total_revenue,
    rc.total_quantity,
    rc.avg_discount,
    rc.region_rank
FROM
    ranked_customers rc
WHERE
    rc.region_rank <= 5
ORDER BY
    rc.c_region,
    rc.region_rank
