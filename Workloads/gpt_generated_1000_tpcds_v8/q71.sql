WITH joined_data AS (
   SELECT
       ws.ws_order_number,
       ws.ws_sold_date_sk,
       ws.ws_item_sk,
       ws.ws_bill_customer_sk,
       ws.ws_quantity,
       ws.ws_net_paid,
       ws.ws_net_profit,
       ws.ws_warehouse_sk,
       ws.ws_promo_sk,
       ws.ws_web_site_sk,
       i.i_category,
       c.c_customer_id,
       cd.cd_gender,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       w.w_state AS w_state,
       p.p_promo_name,
       ws_site.web_country AS web_country,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cp.cp_catalog_number,
       rs.r_reason_desc,
       sr.sr_return_amt,
       sr.sr_return_quantity,
       inv.inv_quantity_on_hand,
       ws_d.d_year AS year,
       inv_d.d_month_seq AS inv_month_seq
   FROM web_sales ws
   JOIN date_dim ws_d ON ws.ws_sold_date_sk = ws_d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
   LEFT JOIN catalog_returns cr
       ON cr.cr_item_sk = i.i_item_sk
      AND cr.cr_returned_date_sk = ws_d.d_date_sk
      AND cr.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN catalog_page cp
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN reason rs
       ON cr.cr_reason_sk = rs.r_reason_sk
   LEFT JOIN store_returns sr
       ON sr.sr_item_sk = i.i_item_sk
      AND sr.sr_returned_date_sk = ws_d.d_date_sk
      AND sr.sr_customer_sk = c.c_customer_sk
   LEFT JOIN inventory inv
       ON inv.inv_item_sk = i.i_item_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN date_dim inv_d
       ON inv.inv_date_sk = inv_d.d_date_sk
),
agg AS (
   SELECT
       year,
       i_category,
       w_state,
       SUM(ws_net_paid) AS total_sales,
       SUM(ws_net_profit) AS total_profit,
       SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_return_amount,
       SUM(COALESCE(sr_return_amt, 0)) AS total_store_return_amount
   FROM joined_data
   WHERE year BETWEEN 2001 AND 2002
     AND i_category = 'Sports'
     AND w_state = 'CA'
     AND web_country = 'United States'
     AND inv_month_seq = 12
   GROUP BY year, i_category, w_state
)
SELECT
   year,
   i_category,
   w_state,
   total_sales,
   total_profit,
   total_catalog_return_amount,
   total_store_return_amount,
   ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 100
