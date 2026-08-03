WITH
  store_part AS (
    SELECT
      d.d_year,
      i.i_brand,
      i.i_category,
      i.i_brand_id,
      ss.ss_net_paid      AS sale_amount,
      ss.ss_net_profit    AS profit,
      sr.sr_return_amt    AS return_amount,
      sr.sr_net_loss      AS net_loss,
      c.c_customer_sk     AS customer_sk,
      r.r_reason_desc     AS reason_desc,
      ib.ib_upper_bound   AS income_upper_bound,
      p.p_promo_name      AS promo_name,
      CAST(NULL AS VARCHAR) AS call_center_name
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr   ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r           ON sr.sr_reason_sk = r.r_reason_sk
  ),
  catalog_part AS (
    SELECT
      d.d_year,
      i.i_brand,
      i.i_category,
      i.i_brand_id,
      cs.cs_net_paid      AS sale_amount,
      cs.cs_net_profit    AS profit,
      cr.cr_return_amount AS return_amount,
      cr.cr_net_loss      AS net_loss,
      c.c_customer_sk     AS customer_sk,
      r.r_reason_desc     AS reason_desc,
      ib.ib_upper_bound   AS income_upper_bound,
      p.p_promo_name      AS promo_name,
      cc.cc_name          AS call_center_name
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r           ON cr.cr_reason_sk = r.r_reason_sk
  ),
  web_part AS (
    SELECT
      d.d_year,
      i.i_brand,
      i.i_category,
      i.i_brand_id,
      ws.ws_net_paid      AS sale_amount,
      ws.ws_net_profit    AS profit,
      wr.wr_return_amt    AS return_amount,
      wr.wr_net_loss      AS net_loss,
      c.c_customer_sk     AS customer_sk,
      r.r_reason_desc     AS reason_desc,
      ib.ib_upper_bound   AS income_upper_bound,
      p.p_promo_name      AS promo_name,
      CAST(NULL AS VARCHAR) AS call_center_name
    FROM web_sales ws
    JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i                   ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c               ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p              ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site ws_site         ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr    ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r           ON wr.wr_reason_sk = r.r_reason_sk
  ),
  unified AS (
    SELECT * FROM store_part
    UNION DISTINCT
    SELECT * FROM catalog_part
    UNION DISTINCT
    SELECT * FROM web_part
  )
SELECT
  d_year,
  i_brand,
  SUM(sale_amount)                      AS total_sales,
  AVG(profit)                           AS avg_profit,
  COUNT(DISTINCT customer_sk)           AS distinct_customers,
  SUM(DISTINCT income_upper_bound)      AS sum_distinct_income_upper,
  COUNT(*)                               AS row_cnt
FROM unified
WHERE d_year = 2001
  AND i_brand_id = 5
  AND i_brand = 'Brand1'
  AND i_category = 'Electronics'
  AND income_upper_bound >= 150000
  AND promo_name = 'Summer Promo'
GROUP BY GROUPING SETS (
  (d_year, i_brand),
  (d_year),
  ()
)
ORDER BY d_year, i_brand
LIMIT 100
