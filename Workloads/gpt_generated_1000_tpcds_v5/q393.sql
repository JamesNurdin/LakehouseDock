WITH agg_sales AS (
  SELECT
    sm.sm_ship_mode_id,
    wsite.web_site_id,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(wr.wr_net_loss) AS return_loss
  FROM catalog_sales cs
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN store_sales ss
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  WHERE cs.cs_quantity > 40
    AND ws.ws_net_paid_inc_ship > 1000
    AND ss.ss_net_profit > 0
    AND EXISTS (
        SELECT 1
        FROM customer_address ca
        WHERE ca.ca_address_sk = cs.cs_bill_addr_sk
          AND ca.ca_state = 'CA'
    )
  GROUP BY sm.sm_ship_mode_id, wsite.web_site_id
)
SELECT
  a.sm_ship_mode_id,
  AVG(a.total_profit) AS avg_total_profit,
  SUM(a.catalog_profit) AS sum_catalog_profit,
  SUM(a.store_profit)   AS sum_store_profit,
  SUM(a.web_profit)     AS sum_web_profit,
  SUM(a.return_loss)    AS sum_return_loss
FROM (
  SELECT
    sm_ship_mode_id,
    web_site_id,
    (catalog_profit + store_profit + web_profit - return_loss) AS total_profit,
    catalog_profit,
    store_profit,
    web_profit,
    return_loss
  FROM agg_sales
) a
GROUP BY a.sm_ship_mode_id
HAVING AVG(a.total_profit) > 1000
ORDER BY avg_total_profit DESC
LIMIT 100
