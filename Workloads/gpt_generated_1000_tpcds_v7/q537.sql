WITH joined AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    ss.ss_sold_date_sk AS sale_date_sk,
    td.t_hour,
    ss.ss_net_profit AS store_net_profit,
    ws.ws_net_profit AS web_net_profit,
    cr.cr_net_loss AS return_net_loss,
    cc.cc_manager,
    we.web_country,
    ca.ca_gmt_offset
  FROM time_dim td
  JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = td.t_time_sk
  LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
)
SELECT
  s_store_name,
  sale_date_sk,
  total_profit,
  RANK() OVER (PARTITION BY sale_date_sk ORDER BY total_profit DESC) AS profit_rank
FROM (
  SELECT
    s_store_name,
    sale_date_sk,
    COALESCE(SUM(store_net_profit), 0) +
    COALESCE(SUM(web_net_profit), 0) -
    COALESCE(SUM(return_net_loss), 0) AS total_profit
  FROM joined
  WHERE
    t_hour BETWEEN 9 AND 17
    AND s_state = 'CA'
    AND cc_manager = 'Miguel Bird'
    AND web_country = 'United States'
    AND ca_gmt_offset > 0
  GROUP BY s_store_name, sale_date_sk
) agg
ORDER BY total_profit DESC
LIMIT 100
