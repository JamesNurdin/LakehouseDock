WITH sales_agg AS (
   SELECT
       hd_bill.hd_demo_sk AS demo_sk,
       hd_bill.hd_buy_potential,
       SUM(ws.ws_net_profit) AS total_net_profit,
       COUNT(*) AS sales_cnt,
       SUM(ws.ws_quantity) AS total_quantity,
       AVG(ws.ws_sales_price) AS avg_sales_price
   FROM tpcds.web_sales ws
   JOIN tpcds.household_demographics hd_bill
     ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   WHERE ws.ws_sales_price > 20
     AND ws.ws_quantity >= 1
     AND hd_bill.hd_vehicle_count >= 0
     AND hd_bill.hd_buy_potential IN ('1001-5000', '5001-10000')
   GROUP BY hd_bill.hd_demo_sk, hd_bill.hd_buy_potential
),

returns_agg AS (
   SELECT
       hd_ref.hd_demo_sk AS demo_sk,
       SUM(wr.wr_return_amt) AS total_return_amt,
       SUM(wr.wr_account_credit) AS total_account_credit,
       COUNT(*) AS return_cnt
   FROM tpcds.web_returns wr
   JOIN tpcds.household_demographics hd_ref
     ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   WHERE wr.wr_return_amt > 0
     AND wr.wr_account_credit > 10
     AND hd_ref.hd_dep_count <= 5
   GROUP BY hd_ref.hd_demo_sk
),

combined AS (
   SELECT
       s.demo_sk,
       s.hd_buy_potential,
       s.total_net_profit,
       s.sales_cnt,
       s.total_quantity,
       s.avg_sales_price,
       COALESCE(r.total_return_amt, 0) AS total_return_amt,
       COALESCE(r.total_account_credit, 0) AS total_account_credit,
       COALESCE(r.return_cnt, 0) AS return_cnt,
       (s.total_net_profit - COALESCE(r.total_return_amt, 0)) AS net_profit_after_returns
   FROM sales_agg s
   LEFT JOIN returns_agg r
     ON s.demo_sk = r.demo_sk
)
SELECT
   demo_sk,
   hd_buy_potential,
   net_profit_after_returns,
   sales_cnt,
   return_cnt,
   avg_sales_price
FROM combined
WHERE net_profit_after_returns > 0
  AND sales_cnt >= 10
  AND return_cnt <= 5
  AND avg_sales_price BETWEEN 30 AND 200
ORDER BY net_profit_after_returns DESC
LIMIT 100
