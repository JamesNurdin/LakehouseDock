WITH item_words AS (
    SELECT i.i_item_sk,
           i.i_category,
           i.i_brand,
           word
    FROM item i
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
)
SELECT d_ss.d_year AS year,
       i.i_category,
       i.i_brand,
       iw.word AS description_word,
       SUM(ss.ss_net_paid) AS total_store_sales,
       SUM(ss.ss_net_profit) AS total_store_profit,
       SUM(cs.cs_net_paid) AS total_catalog_sales,
       SUM(cs.cs_net_profit) AS total_catalog_profit,
       SUM(ws.ws_net_paid) AS total_web_sales,
       SUM(ws.ws_net_profit) AS total_web_profit,
       SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
       COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
       COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions,
       COUNT(DISTINCT ws.ws_order_number) AS web_transactions
FROM store_sales ss
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
-- Store Returns
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
-- Catalog Sales
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN customer c_cs_bill ON cs.cs_bill_customer_sk = c_cs_bill.c_customer_sk
JOIN customer_demographics cd_cs_bill ON cs.cs_bill_cdemo_sk = cd_cs_bill.cd_demo_sk
JOIN household_demographics hd_cs_bill ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
JOIN customer c_cs_ship ON cs.cs_ship_customer_sk = c_cs_ship.c_customer_sk
JOIN customer_demographics cd_cs_ship ON cs.cs_ship_cdemo_sk = cd_cs_ship.cd_demo_sk
JOIN household_demographics hd_cs_ship ON cs.cs_ship_hdemo_sk = hd_cs_ship.hd_demo_sk
-- Catalog Returns
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN customer c_cr_refunded ON cr.cr_refunded_customer_sk = c_cr_refunded.c_customer_sk
JOIN customer_demographics cd_cr_refunded ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
JOIN household_demographics hd_cr_refunded ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
JOIN customer c_cr_returning ON cr.cr_returning_customer_sk = c_cr_returning.c_customer_sk
JOIN customer_demographics cd_cr_returning ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
JOIN household_demographics hd_cr_returning ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
-- Web Sales
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN customer c_ws_bill ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN customer c_ws_ship ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
JOIN date_dim d_ws_open ON w.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close ON w.web_close_date_sk = d_ws_close.d_date_sk
-- Item description words
JOIN item_words iw ON i.i_item_sk = iw.i_item_sk
WHERE d_ss.d_date >= DATE '2001-01-01'
  AND d_ss.d_date < DATE '2002-01-01'
  AND EXISTS (
        SELECT 1
        FROM promotion p_check
        WHERE p_check.p_item_sk = i.i_item_sk
          AND p_check.p_discount_active = 'Y'
    )
GROUP BY d_ss.d_year, i.i_category, i.i_brand, iw.word
ORDER BY total_store_sales DESC
LIMIT 100
