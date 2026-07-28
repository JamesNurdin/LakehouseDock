WITH base AS (
  SELECT
    ca.ca_state AS state,
    cd.cd_gender AS gender,
    td.t_hour AS hour,
    cc.cc_company_name AS company_name,
    cs.cs_net_profit AS catalog_profit,
    ss.ss_net_profit AS store_profit,
    ws.ws_net_profit AS web_profit,
    cr.cr_return_amount AS catalog_return,
    sr.sr_fee AS store_fee,
    wr.wr_return_amt AS web_return,
    cs.cs_quantity AS catalog_quantity,
    ss.ss_quantity AS store_quantity,
    ws.ws_quantity AS web_quantity
  FROM time_dim td
  JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
  JOIN customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
  JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
  JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                         AND cr.cr_item_sk = cs.cs_item_sk
  JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
                     AND ss.ss_cdemo_sk = cd.cd_demo_sk
                     AND ss.ss_addr_sk = ca.ca_address_sk
  JOIN store st ON st.s_store_sk = ss.ss_store_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                       AND sr.sr_item_sk = ss.ss_item_sk
  JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
                   AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
                   AND ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
  WHERE td.t_hour BETWEEN 9 AND 17
    AND ca.ca_state = 'TX'
    AND cd.cd_gender = 'M'
    AND cs.cs_quantity > 10
    AND ss.ss_quantity > 5
    AND ws.ws_quantity >= 30
    AND sr.sr_fee > 10
    AND cr.cr_return_amount > 100
    AND wr.wr_return_amt > 50
    AND EXISTS (
        SELECT 1 FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
          AND cp.cp_type = 'monthly'
    )
)
SELECT
  state,
  gender,
  hour,
  AVG(total_profit) AS avg_total_profit,
  COUNT(DISTINCT company_name) AS distinct_companies
FROM (
  SELECT
    state,
    gender,
    hour,
    company_name,
    (catalog_profit + store_profit + web_profit
     - catalog_return - store_fee - web_return) AS total_profit
  FROM base
) t
GROUP BY state, gender, hour
HAVING AVG(total_profit) > 0
ORDER BY avg_total_profit DESC
LIMIT 100
