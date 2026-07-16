WITH sales_agg AS (
  SELECT
    cp.cp_catalog_page_number AS catalog_page_num,
    cp.cp_type,
    p.p_channel_email AS promo_channel,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amt,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(*) AS sales_transactions
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE cp.cp_type = 'monthly'
    AND cp.cp_start_date_sk = 2450906
  GROUP BY cp.cp_catalog_page_number, cp.cp_type, p.p_channel_email
),
returns_agg AS (
  SELECT
    cp.cp_catalog_page_number AS catalog_page_num,
    p.p_channel_email AS promo_channel,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    COUNT(*) AS return_transactions
  FROM catalog_returns cr
  JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cp.cp_type = 'monthly'
    AND cp.cp_start_date_sk = 2450906
  GROUP BY cp.cp_catalog_page_number, p.p_channel_email
)
SELECT
  s.catalog_page_num,
  s.cp_type,
  s.promo_channel,
  s.total_net_profit,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  (s.total_net_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
  s.total_discount_amt,
  s.total_quantity,
  s.sales_transactions,
  COALESCE(r.return_transactions, 0) AS return_transactions,
  COALESCE(r.total_return_qty, 0) AS total_return_quantity
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.catalog_page_num = r.catalog_page_num
 AND s.promo_channel = r.promo_channel
WHERE (s.total_net_profit - COALESCE(r.total_return_loss, 0)) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
