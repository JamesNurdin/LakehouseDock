/*
  Goal: Analyze profitability by warehouse and promotion for sales that involve promotions with names containing "clearance" or "discount", billed to customers in cities starting with "San", and where the associated inventory has more than 100 units on hand. The query also shows the count of orders that were sold at the maximum price observed for each item.
*/
WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_bill_addr_sk,
        (
            SELECT MAX(cs2.cs_sales_price)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = cs.cs_item_sk
        ) AS max_price_for_item
    FROM catalog_sales cs
    WHERE cs.cs_net_profit > 0
)
SELECT
    CONCAT(w.w_warehouse_name, ' - ', p.p_promo_name) AS warehouse_promo,
    SUBSTRING(ca.ca_city, 1, 3) AS city_prefix,
    COUNT(DISTINCT s.cs_order_number) AS order_cnt,
    SUM(s.cs_net_profit) AS total_net_profit,
    AVG(s.cs_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN s.cs_sales_price = s.max_price_for_item THEN 1 ELSE 0 END) AS orders_at_item_max_price
FROM sales s
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca ON s.cs_bill_addr_sk = ca.ca_address_sk
WHERE regexp_like(p.p_promo_name, '(?i)clearance|discount')
  AND ca.ca_city LIKE 'San%'
  AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = s.cs_item_sk
          AND inv.inv_warehouse_sk = w.w_warehouse_sk
          AND inv.inv_quantity_on_hand > 100
      )
GROUP BY
    w.w_warehouse_name,
    p.p_promo_name,
    ca.ca_city
ORDER BY total_net_profit DESC
LIMIT 100
