WITH catalog_agg AS (
  SELECT
    cd.cd_education_status AS education_status,
    hd.hd_buy_potential AS buy_potential,
    'catalog' AS source,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_education_status ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
  FROM catalog_sales cs
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cd.cd_gender = 'F'
    AND hd.hd_buy_potential = '>10000'
    AND cs.cs_net_profit > (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2)
  GROUP BY cd.cd_education_status, hd.hd_buy_potential
),
web_agg AS (
  SELECT
    cd.cd_education_status AS education_status,
    hd.hd_buy_potential AS buy_potential,
    'web' AS source,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_education_status ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
  FROM web_sales ws
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cd.cd_gender = 'M'
    AND hd.hd_buy_potential = '5001-10000'
    AND ws.ws_net_profit > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2)
  GROUP BY cd.cd_education_status, hd.hd_buy_potential
)
SELECT DISTINCT
  education_status,
  buy_potential,
  source,
  total_profit,
  order_cnt,
  profit_rank
FROM (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM web_agg
) AS combined
ORDER BY total_profit DESC
LIMIT 100
