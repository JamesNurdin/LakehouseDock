WITH sales_base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    i.i_item_id,
    i.i_brand,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ca.ca_location_type,
    cs.cs_net_paid,
    cs.cs_quantity
  FROM catalog_sales cs
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
)
SELECT
  sb.i_item_id,
  sb.i_brand,
  sb.cd_gender,
  ib.ib_upper_bound,
  SUM(sb.cs_net_paid)               AS total_net_paid,
  SUM(sb.cs_quantity)               AS total_quantity,
  COUNT(DISTINCT sb.cs_order_number) AS distinct_orders,
  COUNT(DISTINCT cr.cr_return_quantity) AS catalog_return_cnt,
  SUM(cr.cr_net_loss)               AS catalog_return_loss,
  COUNT(DISTINCT sr.sr_ticket_number)   AS store_return_cnt,
  SUM(sr.sr_net_loss)               AS store_return_loss,
  COUNT(DISTINCT wp.wp_web_page_id) AS web_page_visits,
  CASE WHEN SUM(sb.cs_net_paid) > 50000 THEN 'VIP' ELSE 'REGULAR' END AS customer_segment
FROM sales_base sb
LEFT JOIN catalog_returns cr
  ON cr.cr_order_number = sb.cs_order_number
 AND cr.cr_item_sk = sb.cs_item_sk
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = sb.cs_item_sk
LEFT JOIN item i_store
  ON sr.sr_item_sk = i_store.i_item_sk
LEFT JOIN customer c_sr
  ON sr.sr_customer_sk = c_sr.c_customer_sk
LEFT JOIN web_page wp
  ON wp.wp_customer_sk = c_sr.c_customer_sk
LEFT JOIN income_band ib
  ON sb.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY GROUPING SETS (
  (sb.i_item_id, sb.i_brand, sb.cd_gender, ib.ib_upper_bound),
  (sb.i_item_id, sb.i_brand, sb.cd_gender),
  (sb.i_item_id, sb.i_brand),
  ()
)
ORDER BY total_net_paid DESC
LIMIT 100
