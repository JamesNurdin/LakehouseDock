SELECT
  cd_gender,
  cd_marital_status,
  cd_education_status,
  SUM(store_net_profit)      AS total_store_profit,
  SUM(store_net_loss)        AS total_store_loss,
  SUM(catalog_net_profit)    AS total_catalog_profit,
  SUM(catalog_net_loss)      AS total_catalog_loss,
  SUM(web_net_profit)        AS total_web_profit,
  SUM(web_net_loss)          AS total_web_loss,
  SUM(store_quantity + catalog_quantity + web_quantity) AS total_quantity,
  SUM(store_customer_cnt + catalog_customer_cnt + web_customer_cnt) AS total_customer_cnt
FROM (
  -- Store channel
  SELECT
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    SUM(ss.ss_net_profit)                     AS store_net_profit,
    SUM(COALESCE(sr.sr_net_loss, 0))           AS store_net_loss,
    SUM(ss.ss_quantity)                        AS store_quantity,
    COUNT(DISTINCT ss.ss_customer_sk)          AS store_customer_cnt,
    0                                          AS catalog_net_profit,
    0                                          AS catalog_net_loss,
    0                                          AS catalog_quantity,
    0                                          AS catalog_customer_cnt,
    0                                          AS web_net_profit,
    0                                          AS web_net_loss,
    0                                          AS web_quantity,
    0                                          AS web_customer_cnt
  FROM store_sales ss
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics d
    ON ss.ss_cdemo_sk = d.cd_demo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  GROUP BY d.cd_gender, d.cd_marital_status, d.cd_education_status

  UNION ALL

  -- Catalog channel
  SELECT
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    0                                          AS store_net_profit,
    0                                          AS store_net_loss,
    0                                          AS store_quantity,
    0                                          AS store_customer_cnt,
    SUM(cs.cs_net_profit)                     AS catalog_net_profit,
    SUM(COALESCE(cr.cr_net_loss, 0))           AS catalog_net_loss,
    SUM(cs.cs_quantity)                        AS catalog_quantity,
    COUNT(DISTINCT cs.cs_bill_customer_sk)    AS catalog_customer_cnt,
    0                                          AS web_net_profit,
    0                                          AS web_net_loss,
    0                                          AS web_quantity,
    0                                          AS web_customer_cnt
  FROM catalog_sales cs
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics d
    ON cs.cs_bill_cdemo_sk = d.cd_demo_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
  GROUP BY d.cd_gender, d.cd_marital_status, d.cd_education_status

  UNION ALL

  -- Web channel
  SELECT
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    0                                          AS store_net_profit,
    0                                          AS store_net_loss,
    0                                          AS store_quantity,
    0                                          AS store_customer_cnt,
    0                                          AS catalog_net_profit,
    0                                          AS catalog_net_loss,
    0                                          AS catalog_quantity,
    0                                          AS catalog_customer_cnt,
    SUM(ws.ws_net_profit)                     AS web_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0))           AS web_net_loss,
    SUM(ws.ws_quantity)                        AS web_quantity,
    COUNT(DISTINCT ws.ws_bill_customer_sk)    AS web_customer_cnt
  FROM web_sales ws
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics d
    ON ws.ws_bill_cdemo_sk = d.cd_demo_sk
  LEFT JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
  GROUP BY d.cd_gender, d.cd_marital_status, d.cd_education_status
) agg
GROUP BY cd_gender, cd_marital_status, cd_education_status
ORDER BY total_store_profit DESC
LIMIT 20
