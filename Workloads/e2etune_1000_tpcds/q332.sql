WITH catalog_agg AS (
  SELECT
    hd.hd_demo_sk,
    w.w_city,
    SUM(cs.cs_net_paid) AS catalog_net_paid,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    COUNT(*) AS catalog_orders
  FROM catalog_sales cs
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE cs.cs_net_paid > 500
    AND cs.cs_coupon_amt < 200
  GROUP BY hd.hd_demo_sk, w.w_city
),
store_agg AS (
  SELECT
    hd.hd_demo_sk,
    SUM(ss.ss_net_paid) AS store_net_paid,
    SUM(ss.ss_net_profit) AS store_net_profit,
    COUNT(*) AS store_transactions
  FROM store_sales ss
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE ss.ss_net_paid > 500
    AND ss.ss_coupon_amt < 200
  GROUP BY hd.hd_demo_sk
),
return_agg AS (
  SELECT
    hd.hd_demo_sk,
    SUM(wr.wr_net_loss) AS return_net_loss,
    SUM(wr.wr_return_quantity) AS return_quantity
  FROM web_returns wr
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE wr.wr_return_amt > 100
  GROUP BY hd.hd_demo_sk
)
SELECT
  ca.hd_demo_sk,
  hd.hd_buy_potential,
  ca.w_city,
  ca.catalog_net_paid,
  ca.catalog_net_profit,
  ca.catalog_orders,
  sa.store_net_paid,
  sa.store_net_profit,
  sa.store_transactions,
  ra.return_net_loss,
  ra.return_quantity,
  (ca.catalog_net_profit + sa.store_net_profit - ra.return_net_loss) AS net_profit_after_returns
FROM catalog_agg ca
JOIN store_agg sa ON ca.hd_demo_sk = sa.hd_demo_sk
JOIN return_agg ra ON ca.hd_demo_sk = ra.hd_demo_sk
JOIN household_demographics hd ON ca.hd_demo_sk = hd.hd_demo_sk
WHERE ca.catalog_net_profit > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 100
