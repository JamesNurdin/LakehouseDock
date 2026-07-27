SELECT
  ca.ca_state,
  t.t_hour,
  p.p_promo_name,
  SUM(ss.ss_ext_sales_price)               AS total_store_sales,
  SUM(cs.cs_ext_sales_price)               AS total_catalog_sales,
  COUNT(DISTINCT ss.ss_ticket_number)      AS store_txn_cnt,
  COUNT(DISTINCT cs.cs_order_number)       AS catalog_order_cnt,
  AVG(ss.ss_quantity)                     AS avg_store_qty,
  AVG(cs.cs_quantity)                     AS avg_catalog_qty,
  MIN(ss.ss_quantity)                     AS min_store_qty,
  MAX(ss.ss_quantity)                     AS max_store_qty
FROM store_sales ss
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
  AND cs.cs_promo_sk     = p.p_promo_sk
  AND cs.cs_sold_time_sk = t.t_time_sk
WHERE ss.ss_quantity > 20
  AND ca.ca_county = 'Maricopa County'
  AND p.p_discount_active = 'Y'
  AND t.t_hour BETWEEN 10 AND 16
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_ship_addr_sk = ca.ca_address_sk
          AND cs2.cs_quantity > 30
          AND cs2.cs_promo_sk = p.p_promo_sk
      )
GROUP BY ca.ca_state, t.t_hour, p.p_promo_name
ORDER BY total_store_sales DESC
LIMIT 100
