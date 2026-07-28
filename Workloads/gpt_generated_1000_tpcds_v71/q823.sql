WITH min_promo AS (
    SELECT p_item_sk, MIN(p_cost) AS min_promo_cost
    FROM promotion
    GROUP BY p_item_sk
)
SELECT
    w.web_market_manager,
    i.i_category,
    ca.ca_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
    SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
    AVG(ws.ws_net_paid_inc_tax) AS avg_web_sales,
    MIN(ss.ss_ext_discount_amt) AS min_store_discount,
    MAX(ss.ss_ext_discount_amt) AS max_store_discount,
    CASE
        WHEN SUM(ss.ss_net_paid_inc_tax) > 100000 THEN 'HIGH'
        WHEN SUM(ss.ss_net_paid_inc_tax) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_volume_category,
    (SELECT MAX(i2.i_current_price)
       FROM item i2
      WHERE i2.i_category = i.i_category) AS max_price_in_category
FROM store_sales ss
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN min_promo mp
  ON i.i_item_sk = mp.p_item_sk
JOIN web_sales ws
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site w
  ON ws.ws_web_site_sk = w.web_site_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
WHERE ca.ca_gmt_offset = -5.00
  AND i.i_current_price > 100.00
  AND p.p_discount_active = 'Y'
  AND w.web_market_manager = 'John Sheppard'
  AND w.web_mkt_id IN (1, 3, 4)
  AND ss.ss_net_paid_inc_tax BETWEEN 500 AND 2000
  AND mp.min_promo_cost < 30
  AND EXISTS (
        SELECT 1
          FROM promotion p2
         WHERE p2.p_item_sk = i.i_item_sk
           AND p2.p_cost < 50
      )
GROUP BY w.web_market_manager, i.i_category, ca.ca_state
ORDER BY total_store_sales DESC
LIMIT 100
