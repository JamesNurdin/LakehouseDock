WITH cs AS (
    SELECT cs.cs_warehouse_sk,
           cs.cs_bill_cdemo_sk,
           cs.cs_net_profit,
           cs.cs_ext_tax,
           cs.cs_sold_date_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2451910 + 365
      AND cs.cs_ext_tax > 20
),
ss AS (
    SELECT ss.ss_store_sk,
           ss.ss_cdemo_sk,
           ss.ss_net_profit,
           ss.ss_ext_tax,
           ss.ss_sold_date_sk
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2451910 AND 2451910 + 365
      AND ss.ss_ext_tax > 20
),
wr AS (
    SELECT wr.wr_reason_sk,
           wr.wr_returning_cdemo_sk,
           SUM(wr.wr_net_loss) AS total_return_loss,
           SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2451910 AND 2451910 + 365
    GROUP BY wr.wr_reason_sk, wr.wr_returning_cdemo_sk
)
SELECT w.w_city,
       r.r_reason_desc,
       SUM(cs.cs_net_profit) AS catalog_net_profit,
       SUM(ss.ss_net_profit) AS store_net_profit,
       COALESCE(SUM(wr.total_return_loss), 0) AS total_return_loss,
       COUNT(DISTINCT cd.cd_demo_sk) AS customer_count
FROM cs
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ss ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN wr ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
GROUP BY w.w_city, r.r_reason_desc
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY catalog_net_profit DESC
LIMIT 50
