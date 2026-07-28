WITH
  catalog_data AS (
    SELECT
      cs.cs_order_number        AS order_number,
      cs.cs_item_sk             AS item_sk,
      i.i_brand                 AS brand,
      cs.cs_net_profit          AS net_profit,
      cs.cs_quantity            AS quantity,
      cc.cc_name                AS call_center_name,
      td.t_hour                 AS sold_hour,
      cd.cd_gender              AS bill_gender,
      hd.hd_income_band_sk      AS bill_income_band
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_net_profit > 0
  ),
  web_data AS (
    SELECT
      ws.ws_order_number        AS order_number,
      ws.ws_item_sk             AS item_sk,
      i2.i_brand                AS brand,
      ws.ws_net_profit          AS net_profit,
      ws.ws_quantity            AS quantity,
      wp.wp_type                AS web_page_type,
      td2.t_hour                AS sold_hour,
      cd2.cd_gender             AS bill_gender,
      hd2.hd_income_band_sk     AS bill_income_band
    FROM web_sales ws
    JOIN item i2
      ON ws.ws_item_sk = i2.i_item_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim td2
      ON ws.ws_sold_time_sk = td2.t_time_sk
    JOIN customer_demographics cd2
      ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2
      ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    WHERE ws.ws_net_profit > 0
  ),
  combined AS (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM web_data
  ),
  return_loss AS (
    SELECT
      cr.cr_order_number AS order_number,
      cr.cr_net_loss     AS loss
    FROM catalog_returns cr
    WHERE cr.cr_net_loss > 0
    UNION ALL
    SELECT
      wr.wr_order_number AS order_number,
      wr.wr_net_loss     AS loss
    FROM web_returns wr
    WHERE wr.wr_net_loss > 0
  )
SELECT
  c.brand                                    AS brand,
  SUM(c.net_profit)                          AS total_net_profit,
  SUM(c.quantity)                            AS total_quantity,
  COALESCE(SUM(r.loss), 0)                   AS total_return_loss
FROM combined c
LEFT JOIN return_loss r
  ON c.order_number = r.order_number
WHERE EXISTS (
  SELECT 1
  FROM promotion p
  WHERE p.p_item_sk = c.item_sk
    AND p.p_discount_active = 'Y'
)
GROUP BY c.brand
HAVING SUM(c.net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
