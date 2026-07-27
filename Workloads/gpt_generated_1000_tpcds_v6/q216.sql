WITH promo_cost AS (
    SELECT p_promo_sk, MAX(p_cost) AS max_cost
    FROM promotion
    GROUP BY p_promo_sk
)
SELECT
    cp.cp_department,
    ca.ca_state,
    td.t_hour,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    promo_cost.max_cost AS max_promo_cost
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN promo_cost ON cs.cs_promo_sk = promo_cost.p_promo_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND cp.cp_department = 'Electronics'
  AND cs.cs_quantity > 2
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = cs.cs_promo_sk
          AND p.p_discount_active = 'Y'
          AND p.p_start_date_sk >= 2451080
          AND p.p_start_date_sk <= 2451100
    )
GROUP BY cp.cp_department, ca.ca_state, td.t_hour, promo_cost.max_cost
ORDER BY total_net_paid DESC
LIMIT 100
