/*
Goal: Calculate, per store and promotion, the total net sales and total net loss from catalog, store, and web returns for the year 2001, considering only stores that have associated web returns. The query joins all ten selected tables, re‑uses the date_dim table under two aliases, applies a semi‑join via EXISTS, includes a DISTINCT aggregation, orders by total net sales and limits the output.
*/
WITH
  d_sales AS (
    SELECT d_date_sk, d_year, d_date
    FROM   date_dim
    WHERE  d_year = 2001
  ),
  d_return AS (
    SELECT d_date_sk, d_year
    FROM   date_dim
  )
SELECT
  st.s_store_id,
  st.s_store_name,
  p.p_promo_name,
  COUNT(DISTINCT ss.ss_ticket_number)               AS distinct_tickets,
  SUM(ss.ss_net_paid)                               AS total_net_paid,
  SUM(cr.cr_net_loss)                               AS total_catalog_return_loss,
  SUM(sr.sr_net_loss)                               AS total_store_return_loss,
  SUM(wr.wr_net_loss)                               AS total_web_return_loss
FROM
  store_sales ss
JOIN d_sales d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store st
  ON ss.ss_store_sk = st.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
  ON sr.sr_item_sk          = ss.ss_item_sk
 AND sr.sr_store_sk         = st.s_store_sk
 AND sr.sr_ticket_number    = ss.ss_ticket_number
JOIN d_return d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
  EXISTS (
    SELECT 1
    FROM   web_returns wr2
    WHERE  wr2.wr_web_page_sk = wp.wp_web_page_sk
      AND  wr2.wr_returned_date_sk = d_ret.d_date_sk
      AND  wr2.wr_return_quantity > 0
  )
  AND st.s_country = 'United States'
GROUP BY
  st.s_store_id,
  st.s_store_name,
  p.p_promo_name
ORDER BY
  total_net_paid DESC
LIMIT 100
