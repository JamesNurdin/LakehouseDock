WITH demo_metrics AS (
  SELECT
    cc.cc_name,
    cd_bill.cd_gender AS bill_gender,
    cd_bill.cd_marital_status AS bill_marital,
    cd_ship.cd_gender AS ship_gender,
    cd_ship.cd_marital_status AS ship_marital,
    AVG(cs.cs_net_paid) AS avg_net_paid,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    COUNT(*) AS order_cnt
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  GROUP BY cc.cc_name, cd_bill.cd_gender, cd_bill.cd_marital_status,
           cd_ship.cd_gender, cd_ship.cd_marital_status
)
SELECT
  cc_name,
  bill_gender,
  bill_marital,
  ship_gender,
  ship_marital,
  avg_net_paid,
  avg_net_profit,
  order_cnt,
  (avg_net_profit - avg_net_paid) AS profit_gap,
  ROW_NUMBER() OVER (ORDER BY (avg_net_profit - avg_net_paid) DESC) AS profit_gap_rank,
  CASE
    WHEN (avg_net_profit - avg_net_paid) > 0 THEN 'Profit'
    ELSE 'Loss'
  END AS profit_status
FROM demo_metrics
WHERE order_cnt >= 10
ORDER BY profit_gap_rank
LIMIT 10
