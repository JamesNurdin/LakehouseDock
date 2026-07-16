WITH catalog_agg AS (
  SELECT cc.cc_name AS location,
         cd.cd_gender AS gender,
         SUM(cs.cs_net_profit) AS net_profit,
         SUM(cs.cs_quantity) AS quantity
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
    AND cc.cc_employees > 2000000
    AND cd.cd_gender = 'M'
  GROUP BY cc.cc_name, cd.cd_gender
  HAVING SUM(cs.cs_net_profit) > 1000
),
web_agg AS (
  SELECT ws_site.web_name AS location,
         cd.cd_gender AS gender,
         SUM(ws.ws_net_profit) AS net_profit,
         SUM(ws.ws_quantity) AS quantity
  FROM web_sales ws
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
    AND ws_site.web_gmt_offset = -5.00
    AND cd.cd_gender = 'M'
  GROUP BY ws_site.web_name, cd.cd_gender
  HAVING SUM(ws.ws_net_profit) > 500
),
returns_agg AS (
  SELECT cc.cc_name AS location,
         cd.cd_gender AS gender,
         SUM(cr.cr_refunded_cash) AS total_refunded_cash,
         SUM(cr.cr_return_quantity) AS return_quantity
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
    AND cc.cc_employees > 2000000
    AND cd.cd_gender = 'M'
  GROUP BY cc.cc_name, cd.cd_gender
  HAVING SUM(cr.cr_refunded_cash) > 100
)
SELECT 'catalog' AS channel,
       ca.location,
       ca.gender,
       ca.net_profit,
       ca.quantity,
       CAST(NULL AS decimal(7,2)) AS web_net_profit,
       CAST(NULL AS integer) AS web_quantity,
       CAST(NULL AS decimal(7,2)) AS total_refunded_cash
FROM catalog_agg ca
UNION ALL
SELECT 'web' AS channel,
       wa.location,
       wa.gender,
       CAST(NULL AS decimal(7,2)) AS net_profit,
       CAST(NULL AS integer) AS quantity,
       wa.net_profit AS web_net_profit,
       wa.quantity AS web_quantity,
       CAST(NULL AS decimal(7,2)) AS total_refunded_cash
FROM web_agg wa
UNION ALL
SELECT 'returns' AS channel,
       ra.location,
       ra.gender,
       CAST(NULL AS decimal(7,2)) AS net_profit,
       CAST(NULL AS integer) AS quantity,
       CAST(NULL AS decimal(7,2)) AS web_net_profit,
       CAST(NULL AS integer) AS web_quantity,
       ra.total_refunded_cash
FROM returns_agg ra
ORDER BY channel, location, gender
