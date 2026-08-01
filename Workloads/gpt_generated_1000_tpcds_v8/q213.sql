WITH store_data AS (
  SELECT
    ss.ss_item_sk,
    ss.ss_sold_date_sk,
    ss.ss_store_sk,
    ss.ss_customer_sk,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    ss.ss_ticket_number,
    ss.ss_quantity,
    i.i_brand,
    i.i_current_price,
    s.s_state,
    s.s_country,
    p.p_promo_name,
    ca.ca_address_sk
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE i.i_brand = 'barableable'
    AND s.s_country = 'United States'
),

inventory_data AS (
  SELECT inv.inv_item_sk, inv.inv_quantity_on_hand
  FROM inventory inv
  JOIN item i ON inv.inv_item_sk = i.i_item_sk
  WHERE inv.inv_quantity_on_hand > 0
),

web_items AS (
  SELECT DISTINCT ws.ws_item_sk
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
  WHERE p.p_promo_name LIKE '%Clearance%'
),

store_items AS (
  SELECT DISTINCT ss.ss_item_sk
  FROM store_sales ss
),

common_items AS (
  SELECT ss_item_sk
  FROM store_items
  INTERSECT
  SELECT ws_item_sk
  FROM web_items
),

store_only_items AS (
  SELECT ss_item_sk
  FROM store_items
  EXCEPT
  SELECT ws_item_sk
  FROM web_items
),

final AS (
  SELECT
    i.i_brand,
    s.s_state,
    COUNT(DISTINCT sd.ss_customer_sk) AS unique_customers,
    SUM(sd.ss_ext_sales_price) AS total_store_sales,
    SUM(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_return_quantity ELSE 0 END) AS total_return_qty,
    SUM(sr.sr_refunded_cash) AS total_refunds,
    AVG(i.i_current_price) AS avg_item_price,
    SUM(sd.ss_net_profit) AS total_net_profit,
    SUM(CASE WHEN sr.sr_return_quantity > 0 THEN 1 ELSE 0 END) AS return_transactions
  FROM store_data sd
  JOIN store s ON sd.ss_store_sk = s.s_store_sk
  JOIN item i ON sd.ss_item_sk = i.i_item_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = sd.ss_ticket_number
   AND sr.sr_item_sk = sd.ss_item_sk
  JOIN inventory_data inv ON inv.inv_item_sk = sd.ss_item_sk
  WHERE sd.ss_item_sk IN (SELECT ss_item_sk FROM common_items)
    AND NOT EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_ticket_number = sd.ss_ticket_number
          AND sr2.sr_refunded_cash > 500
    )
  GROUP BY i.i_brand, s.s_state
)
SELECT
  i_brand,
  s_state,
  unique_customers,
  total_store_sales,
  total_return_qty,
  total_refunds,
  avg_item_price,
  total_net_profit,
  return_transactions
FROM final
ORDER BY total_store_sales DESC
LIMIT 20
