WITH ss_agg AS (
   SELECT
       ss_item_sk,
       ss_promo_sk,
       SUM(ss_ext_sales_price) AS total_store_sales,
       SUM(ss_quantity) AS total_store_qty,
       COUNT(DISTINCT ss_ticket_number) AS store_transactions
   FROM store_sales
   WHERE ss_ext_sales_price > 1000
     AND ss_quantity >= 1
     AND ss_sold_time_sk BETWEEN 60000 AND 72000
     AND ss_wholesale_cost < 50
     AND ss_ext_discount_amt BETWEEN 0 AND 500
   GROUP BY ss_item_sk, ss_promo_sk
)
SELECT
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    SUM(wa.total_store_sales) AS sum_store_sales,
    SUM(ws.ws_ext_sales_price) AS sum_web_sales,
    CASE
        WHEN SUM(wa.total_store_sales) > 1.2 * SUM(ws.ws_ext_sales_price) THEN 'Store Dominant'
        ELSE 'Web Dominant'
    END AS sales_channel_indicator,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    AVG(i.i_current_price) AS avg_item_price
FROM ss_agg wa
JOIN item i
  ON wa.ss_item_sk = i.i_item_sk
JOIN promotion p
  ON wa.ss_promo_sk = p.p_promo_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
WHERE p.p_purpose = 'Unknown'
  AND i.i_current_price BETWEEN 10 AND 2000
  AND wp.wp_image_count > 2
  AND ca_bill.ca_state = 'CA'
  AND ca_ship.ca_country = 'United States'
GROUP BY i.i_category, i.i_brand, p.p_promo_name
HAVING SUM(wa.total_store_sales) > 5000
ORDER BY sum_store_sales DESC
LIMIT 100
