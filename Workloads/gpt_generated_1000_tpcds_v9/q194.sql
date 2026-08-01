WITH base AS (
  SELECT
    i.i_brand,
    i.i_brand_id,
    p.p_promo_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.ss_net_profit AS store_profit,
    ws.ws_net_profit AS web_profit,
    cr.cr_net_loss AS catalog_return_loss,
    wr.wr_net_loss AS web_return_loss,
    c.c_customer_id,
    cd.cd_gender,
    ca.ca_state,
    cc.cc_name AS call_center_name,
    r_cr.r_reason_desc AS catalog_return_reason,
    r_wr.r_reason_desc AS web_return_reason,
    wsite.web_name AS web_site_name
  FROM store_sales ss
  INNER JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  INNER JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  INNER JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  INNER JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  INNER JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  INNER JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
  LEFT JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
)
SELECT
  brand,
  promo_name,
  lower_bound,
  upper_bound,
  total_sales_profit,
  total_return_loss,
  net_total,
  ROW_NUMBER() OVER (PARTITION BY brand ORDER BY net_total DESC) AS brand_rank
FROM (
  SELECT
    i_brand AS brand,
    p_promo_name AS promo_name,
    ib_lower_bound AS lower_bound,
    ib_upper_bound AS upper_bound,
    COALESCE(SUM(store_profit), 0) + COALESCE(SUM(web_profit), 0) AS total_sales_profit,
    COALESCE(SUM(catalog_return_loss), 0) + COALESCE(SUM(web_return_loss), 0) AS total_return_loss,
    COALESCE(SUM(store_profit), 0) + COALESCE(SUM(web_profit), 0) -
      (COALESCE(SUM(catalog_return_loss), 0) + COALESCE(SUM(web_return_loss), 0)) AS net_total
  FROM base
  GROUP BY ROLLUP (i_brand, p_promo_name, ib_lower_bound, ib_upper_bound)
) agg
ORDER BY net_total DESC
LIMIT 100
