WITH
  sr AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_item_sk,
      sr.sr_customer_sk,
      sr.sr_cdemo_sk,
      sr.sr_hdemo_sk,
      sr.sr_store_sk,
      sr.sr_reason_sk,
      sr.sr_net_loss,
      d.d_year               AS return_year,
      i.i_category,
      i.i_brand,
      c.c_preferred_cust_flag,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      r.r_reason_desc
    FROM store_returns sr
    JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i                   ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r                 ON sr.sr_reason_sk = r.r_reason_sk
  ),
  cs AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_item_sk,
      cs.cs_bill_customer_sk,
      cs.cs_net_paid,
      cs.cs_quantity,
      cs.cs_order_number,
      d.d_year               AS sales_year,
      cs.cs_call_center_sk,
      cs.cs_promo_sk,
      p.p_promo_name,
      p.p_channel_email,
      p.p_channel_dmail
    FROM catalog_sales cs
    JOIN date_dim d   ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p   ON cs.cs_promo_sk = p.p_promo_sk
  ),
  ws AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_bill_customer_sk,
      ws.ws_net_profit,
      ws.ws_order_number,
      d.d_year               AS web_sales_year,
      ws.ws_web_page_sk,
      ws.ws_web_site_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  ),
  wr AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_order_number,
      wr.wr_net_loss,
      d.d_year               AS web_return_year,
      r.r_reason_desc        AS web_return_reason
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r   ON wr.wr_reason_sk = r.r_reason_sk
  ),
  cc AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_market_manager,
      d.d_year               AS cc_year
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
  ),
  wp AS (
    SELECT
      wp.wp_web_page_sk,
      wp.wp_url,
      wp.wp_type,
      d.d_year               AS wp_year,
      c.c_customer_sk
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
  ),
  ws_site AS (
    SELECT
      ws.web_site_sk,
      ws.web_name,
      d.d_year               AS site_year
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
  )
SELECT
  s.s_store_name,
  s.s_state,
  sr.return_year,
  i.i_category,
  SUM(cs.cs_net_paid)          AS total_sales_paid,
  SUM(sr.sr_net_loss)          AS total_store_return_loss,
  SUM(ws.ws_net_profit)        AS total_web_profit,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  AVG(cs.cs_quantity)          AS avg_quantity_sold
FROM sr
RIGHT OUTER JOIN store s ON s.s_store_sk = sr.sr_store_sk
JOIN cs   ON cs.cs_item_sk = sr.sr_item_sk
           AND cs.cs_bill_customer_sk = sr.sr_customer_sk
JOIN ws   ON ws.ws_item_sk = sr.sr_item_sk
           AND ws.ws_bill_customer_sk = sr.sr_customer_sk
JOIN cc   ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN wr   ON wr.wr_item_sk = ws.ws_item_sk
           AND wr.wr_order_number = ws.ws_order_number
JOIN wp   ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE
  sr.return_year = 2001
  AND p.p_channel_email = 'Y'
  AND i.i_brand = 'Brand#23'
  AND s.s_state = 'CA'
  AND sr.c_preferred_cust_flag = 'Y'
GROUP BY
  s.s_store_name,
  s.s_state,
  sr.return_year,
  i.i_category
ORDER BY
  total_sales_paid DESC
LIMIT 100
