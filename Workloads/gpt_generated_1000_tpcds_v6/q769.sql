WITH all_data AS (
  SELECT
    s.s_store_name,
    ca.ca_state,
    p.p_discount_active,
    t_sold.t_hour AS sold_hour,
    ss.ss_ext_sales_price            AS store_sales_amount,
    ss.ss_net_profit                 AS store_profit,
    sr.sr_return_quantity            AS store_return_qty,
    r.r_reason_desc                  AS store_return_reason,
    cr.cr_return_quantity            AS catalog_return_qty,
    cr_r.r_reason_desc               AS catalog_return_reason,
    ws.ws_ext_sales_price            AS web_sales_amount,
    ws.ws_net_profit                 AS web_profit,
    we.web_name                      AS web_site_name,
    cd.cd_gender,
    hd.hd_income_band_sk
  FROM store_sales ss
  JOIN store s               ON ss.ss_store_sk      = s.s_store_sk
  JOIN time_dim t_sold       ON ss.ss_sold_time_sk = t_sold.t_time_sk
  JOIN promotion p          ON ss.ss_promo_sk     = p.p_promo_sk
  JOIN customer_address ca  ON ss.ss_addr_sk      = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN store_returns sr   ON sr.sr_item_sk      = ss.ss_item_sk
                               AND sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_store_sk     = s.s_store_sk
  LEFT JOIN reason r           ON sr.sr_reason_sk    = r.r_reason_sk
  LEFT JOIN catalog_returns cr ON cr.cr_item_sk      = ss.ss_item_sk
  LEFT JOIN warehouse w        ON cr.cr_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN reason cr_r        ON cr.cr_reason_sk    = cr_r.r_reason_sk
  LEFT JOIN web_sales ws       ON ws.ws_item_sk      = ss.ss_item_sk
                               AND ws.ws_sold_time_sk = ss.ss_sold_time_sk
  LEFT JOIN web_site we        ON ws.ws_web_site_sk  = we.web_site_sk
  LEFT JOIN time_dim t_web     ON ws.ws_sold_time_sk = t_web.t_time_sk
  WHERE p.p_discount_active = 'Y'
    AND ca.ca_state = 'CA'
    AND t_sold.t_hour BETWEEN 9 AND 17
)
SELECT
  s_store_name,
  ca_state,
  SUM(store_sales_amount) AS total_store_sales,
  SUM(store_profit)      AS total_store_profit,
  SUM(web_sales_amount) AS total_web_sales,
  SUM(web_profit)        AS total_web_profit,
  RANK() OVER (ORDER BY SUM(store_profit) DESC) AS store_profit_rank
FROM all_data
GROUP BY s_store_name, ca_state
ORDER BY store_profit_rank
LIMIT 100
