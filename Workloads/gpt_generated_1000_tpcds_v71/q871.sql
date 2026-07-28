WITH catalog_agg AS (
  SELECT
    cc.cc_name AS channel,
    hd.hd_buy_potential AS buy_potential,
    SUM(cs.cs_net_paid) AS total_net_paid
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cc.cc_state = 'CA'
    AND hd.hd_vehicle_count >= 1
  GROUP BY cc.cc_name, hd.hd_buy_potential
),
web_agg AS (
  SELECT
    CAST('Web' AS varchar) AS channel,
    hd.hd_buy_potential AS buy_potential,
    SUM(ws.ws_net_paid) AS total_net_paid
  FROM web_sales ws
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_dep_count <= 2
    AND ws.ws_ext_wholesale_cost > 1000
  GROUP BY hd.hd_buy_potential
)
SELECT *
FROM (
  SELECT channel, buy_potential, total_net_paid FROM catalog_agg
  UNION ALL
  SELECT channel, buy_potential, total_net_paid FROM web_agg
) combined
ORDER BY total_net_paid DESC
LIMIT 100
