WITH
  -- Store side fact rows with related dimensions
  store_fact AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      s.s_store_name,
      ca.ca_state,
      p.p_promo_name,
      CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_type
    FROM store_sales ss
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca   ON ss.ss_addr_sk   = ca.ca_address_sk
    JOIN promotion p           ON ss.ss_promo_sk  = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100               -- surrogate date range
      AND ss.ss_quantity >= 1
      AND p.p_discount_active = 'Y'
      AND ca.ca_location_type = 'single family'
      AND s.s_state = 'CA'
      AND p.p_channel_dmail = 'Y'
  ),

  -- Store returns side (joined to the same dimensions)
  store_ret AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_refunded_cash,
      CASE WHEN sr.sr_refunded_cash > 500 THEN 'HighRefund' ELSE 'LowRefund' END AS refund_category
    FROM store_returns sr
    JOIN store s               ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca   ON sr.sr_addr_sk   = ca.ca_address_sk
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 0
      AND ca.ca_state = 'CA'
  ),

  -- Full outer join of store sales and returns – keeps unmatched rows from both sides
  store_combined AS (
    SELECT
      sf.ss_ticket_number AS trans_id,
      sf.s_store_name,
      sf.ss_net_paid,
      sf.ss_net_profit,
      sf.purchase_type,
      sr.refund_category
    FROM store_fact sf
    FULL OUTER JOIN store_ret sr
      ON sf.ss_ticket_number = sr.sr_ticket_number
  ),

  -- Catalog side fact rows with related dimensions
  catalog_fact AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      p.p_promo_name,
      ca.ca_state,
      CASE WHEN cs.cs_quantity > 10 THEN 'BulkCatalog' ELSE 'RegularCatalog' END AS purchase_type
    FROM catalog_sales cs
    JOIN promotion p           ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca   ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND cs.cs_quantity >= 1
      AND p.p_discount_active = 'Y'
      AND ca.ca_location_type = 'apartment'
      AND p.p_channel_catalog = 'N'
  ),

  -- Catalog returns side (joined to catalog sales)
  catalog_ret AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      CASE WHEN cr.cr_return_amount > 300 THEN 'LargeReturn' ELSE 'SmallReturn' END AS return_size
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 0
  ),

  -- Full outer join of catalog sales and returns – keeps unmatched rows from both sides
  catalog_combined AS (
    SELECT
      cf.cs_order_number AS trans_id,
      cf.p_promo_name,
      cf.cs_net_paid,
      cf.cs_net_profit,
      cf.purchase_type,
      cr.return_size
    FROM catalog_fact cf
    FULL OUTER JOIN catalog_ret cr
      ON cf.cs_order_number = cr.cr_order_number
  ),

  -- Sets of distinct items on each side
  store_items AS (SELECT DISTINCT ss_item_sk FROM store_fact),
  catalog_items AS (SELECT DISTINCT cs_item_sk FROM catalog_fact),

  -- Items sold in stores but never in the catalog (EXCEPT)
  store_not_in_catalog AS (
    SELECT ss_item_sk FROM store_items
    EXCEPT
    SELECT cs_item_sk FROM catalog_items
  ),

  -- Union of all transaction rows (store + catalog) for aggregation
  all_transactions AS (
    SELECT trans_id,
           purchase_type,
           ss_net_paid  AS net_paid,
           ss_net_profit AS net_profit
    FROM store_combined
    UNION ALL
    SELECT trans_id,
           purchase_type,
           cs_net_paid  AS net_paid,
           cs_net_profit AS net_profit
    FROM catalog_combined
  )

SELECT
  trans_id,
  purchase_type,
  SUM(net_paid)   AS total_net_paid,
  AVG(net_profit) AS avg_net_profit,
  COUNT(*)        AS txn_count
FROM all_transactions
WHERE trans_id IS NOT NULL
GROUP BY trans_id, purchase_type
HAVING SUM(net_paid) > 500
ORDER BY total_net_paid DESC
OFFSET 0 LIMIT 100
