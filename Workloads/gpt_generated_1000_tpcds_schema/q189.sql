WITH
  sales_agg AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_cdemo_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      ss.ss_ticket_number
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_holiday = 'N'
      AND i.i_manufact_id = 86
      AND s.s_state = 'CA'
      AND d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  ),

  returns_full AS (
    SELECT
      COALESCE(cr.cr_returned_date_sk, wr.wr_returned_date_sk) AS return_date_sk,
      COALESCE(cr.cr_item_sk, wr.wr_item_sk) AS item_sk,
      cr.cr_return_quantity,
      wr.wr_return_quantity,
      cr.cr_return_amount,
      wr.wr_return_amt,
      cr.cr_net_loss,
      wr.wr_net_loss,
      cr.cr_refunded_cdemo_sk,
      wr.wr_refunded_cdemo_sk,
      cr.cr_catalog_page_sk
    FROM catalog_returns cr
    FULL OUTER JOIN web_returns wr
      ON cr.cr_returned_date_sk = wr.wr_returned_date_sk
     AND cr.cr_item_sk = wr.wr_item_sk
  )
SELECT
  d.d_year,
  s.s_store_name,
  i.i_category,
  SUM(sa.ss_ext_sales_price) AS total_sales,
  SUM(rf.cr_return_amount) AS total_catalog_return_amount,
  SUM(rf.wr_return_amt) AS total_web_return_amount,
  COUNT(DISTINCT sa.ss_ticket_number) AS distinct_tickets,
  AVG(i.i_current_price) AS avg_item_price,
  MIN(rf.cr_net_loss) AS min_catalog_net_loss,
  MAX(rf.wr_net_loss) AS max_web_net_loss
FROM sales_agg sa
JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN item i ON sa.ss_item_sk = i.i_item_sk
LEFT JOIN returns_full rf
  ON sa.ss_sold_date_sk = rf.return_date_sk
 AND sa.ss_item_sk = rf.item_sk
LEFT JOIN inventory inv
  ON d.d_date_sk = inv.inv_date_sk
 AND i.i_item_sk = inv.inv_item_sk
LEFT JOIN catalog_page cp
  ON rf.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE d.d_year = 2000
GROUP BY d.d_year, s.s_store_name, i.i_category
ORDER BY total_sales DESC
LIMIT 100
