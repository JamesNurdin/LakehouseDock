WITH revenue_by_brand AS (
    SELECT
        order_date.d_year AS order_year,
        customer.c_region AS customer_region,
        part.p_brand1 AS brand,
        SUM(lineorder.lo_revenue) AS brand_revenue
    FROM lineorder
    JOIN dim_date AS order_date
        ON CAST(order_date.d_datekey AS integer) = lineorder.lo_orderdate
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    WHERE order_date.d_date >= '1995-01-01'
      AND order_date.d_date < '1996-01-01'
    GROUP BY
        order_date.d_year,
        customer.c_region,
        part.p_brand1
),
ranked_brands AS (
    SELECT
        order_year,
        customer_region,
        brand,
        brand_revenue,
        RANK() OVER (PARTITION BY order_year, customer_region ORDER BY brand_revenue DESC) AS brand_rank
    FROM revenue_by_brand
)
SELECT
    order_year,
    customer_region,
    brand,
    brand_revenue,
    brand_rank
FROM ranked_brands
WHERE brand_rank <= 5
ORDER BY order_year, customer_region, brand_rank
