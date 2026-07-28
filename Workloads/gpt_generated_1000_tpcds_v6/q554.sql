WITH base AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_brand,
    i.i_category,
    ss.ss_net_paid,
    ss.ss_ticket_number,
    sr.sr_net_loss,
    p.p_cost,
    inv.inv_quantity_on_hand,
    r.r_reason_desc,
    ca.ca_street_type,
    ca.ca_gmt_offset,
    i.i_current_price
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk AND cr.cr_reason_sk = r.r_reason_sk
  WHERE ca.ca_street_type = 'Avenue'
    AND ca.ca_gmt_offset = -5.00
    AND r.r_reason_desc LIKE '%price%'
    AND i.i_current_price > 20.00
    AND EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_item_sk = i.i_item_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    )
),
agg AS (
  SELECT
    s_store_id,
    s_store_name,
    i_brand,
    i_category,
    SUM(ss_net_paid) AS total_sales,
    SUM(sr_net_loss) AS total_return_loss,
    COUNT(DISTINCT ss_ticket_number) AS num_transactions,
    AVG(p_cost) AS avg_promo_cost,
    MIN(inv_quantity_on_hand) AS min_inventory,
    MAX(inv_quantity_on_hand) AS max_inventory
  FROM base
  GROUP BY
    s_store_id,
    s_store_name,
    i_brand,
    i_category
)
SELECT
  s_store_id,
  s_store_name,
  i_brand,
  i_category,
  total_sales,
  total_return_loss,
  num_transactions,
  avg_promo_cost,
  min_inventory,
  max_inventory,
  ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
