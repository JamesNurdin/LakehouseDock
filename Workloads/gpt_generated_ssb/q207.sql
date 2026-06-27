WITH lo_agg AS (
    SELECT lo_partkey,
           SUM(lo_revenue) AS revenue_sum,
           SUM(lo_quantity) AS quantity_sum,
           AVG(lo_discount) AS discount_avg
    FROM lineorder
    WHERE lo_quantity > 0
    GROUP BY lo_partkey
),
part_agg AS (
    SELECT p.p_category,
           p.p_brand1,
           SUM(lo_agg.revenue_sum) AS category_brand_revenue,
           SUM(lo_agg.quantity_sum) AS category_brand_quantity,
           AVG(lo_agg.discount_avg) AS category_brand_avg_discount
    FROM lo_agg
    JOIN part p
      ON lo_agg.lo_partkey = p.p_partkey
    WHERE p.p_size > 10
      AND p.p_color = 'green'
    GROUP BY p.p_category, p.p_brand1
)
SELECT p_category,
       p_brand1,
       category_brand_revenue,
       category_brand_quantity,
       category_brand_avg_discount,
       category_brand_revenue / SUM(category_brand_revenue) OVER (PARTITION BY p_category) AS revenue_share_in_category,
       RANK() OVER (PARTITION BY p_category ORDER BY category_brand_revenue DESC) AS brand_revenue_rank
FROM part_agg
ORDER BY category_brand_revenue DESC
LIMIT 20
