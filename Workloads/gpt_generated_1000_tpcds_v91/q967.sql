/* Goal: Identify top‑performing catalog sales by department and promotion, analysing revenue, order count, price tier and inventory while filtering for specific description patterns, California customers, and excluding any orders that have associated returns. */
WITH cs_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_addr_sk
    FROM catalog_sales cs
    WHERE cs.cs_order_number NOT IN (
        SELECT cr_order_number FROM catalog_returns
    )
)
SELECT
    cp.cp_department,
    p.p_promo_name,
    concat(cp.cp_department, ' - ', p.p_promo_name) AS dept_promo,
    sm.sm_type AS ship_mode_type,
    w.w_state AS warehouse_state,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS orders_count,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    CASE WHEN AVG(cs.cs_sales_price) > 100 THEN 'HIGH' ELSE 'LOW' END AS price_category,
    regexp_extract(cp.cp_description, '[0-9]+') AS description_numeric_code,
    CASE WHEN ca.ca_city LIKE 'A%' THEN 'CITY_A' ELSE 'OTHER_CITY' END AS city_group,
    SUM(i.inv_quantity_on_hand) AS total_inventory
FROM cs_filtered cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE regexp_like(cp.cp_description, '.*[0-9]{2}.*')
  AND ca.ca_state = 'CA'
GROUP BY
    cp.cp_department,
    p.p_promo_name,
    concat(cp.cp_department, ' - ', p.p_promo_name),
    sm.sm_type,
    w.w_state,
    regexp_extract(cp.cp_description, '[0-9]+'),
    CASE WHEN ca.ca_city LIKE 'A%' THEN 'CITY_A' ELSE 'OTHER_CITY' END
ORDER BY total_net_paid DESC
LIMIT 100
