/*
Goal: Compute combined catalog and store net profit per warehouse for 2002 sales to female customers with high purchase estimates, filtered by warehouse zip pattern and web site state, and compare each warehouse's profit to the overall catalog profit.
*/
WITH cs_agg AS (
    SELECT
        cs_warehouse_sk,
        cs_sold_date_sk,
        cs_bill_cdemo_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(*) AS cs_order_cnt
    FROM catalog_sales
    WHERE cs_net_paid > 1000
      AND cs_quantity >= 2
    GROUP BY cs_warehouse_sk, cs_sold_date_sk, cs_bill_cdemo_sk
),
ss_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_cdemo_sk,
        SUM(ss_net_paid) AS ss_total_net_paid,
        SUM(ss_net_profit) AS ss_total_net_profit,
        COUNT(*) AS ss_order_cnt
    FROM store_sales
    WHERE ss_net_paid > 500
      AND ss_quantity >= 1
    GROUP BY ss_sold_date_sk, ss_cdemo_sk
)
SELECT
    w.w_warehouse_name,
    d_date.d_year,
    SUM(cs_agg.total_net_profit) AS catalog_net_profit,
    SUM(ss_agg.ss_total_net_profit) AS store_net_profit,
    SUM(cs_agg.total_net_profit + ss_agg.ss_total_net_profit) AS combined_net_profit,
    SUM(cs_agg.cs_order_cnt) AS catalog_orders,
    SUM(ss_agg.ss_order_cnt) AS store_orders,
    (SELECT AVG(total_net_profit) FROM cs_agg) AS overall_catalog_avg_profit
FROM cs_agg
JOIN warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_date
    ON cs_agg.cs_sold_date_sk = d_date.d_date_sk
JOIN customer_demographics cd_bill
    ON cs_agg.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN ss_agg
    ON ss_agg.ss_sold_date_sk = d_date.d_date_sk
JOIN customer_demographics cd_store
    ON ss_agg.ss_cdemo_sk = cd_store.cd_demo_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_date.d_date_sk
JOIN date_dim d_close
    ON ws.web_close_date_sk = d_close.d_date_sk
WHERE d_date.d_year = 2002
  AND cd_bill.cd_gender = 'F'
  AND cd_bill.cd_purchase_estimate > 5000
  AND (w.w_zip LIKE '64%' OR w.w_zip LIKE '74%')
  AND ws.web_state = 'CA'
  AND d_close.d_year > 2003
GROUP BY w.w_warehouse_name, d_date.d_year
HAVING SUM(cs_agg.total_net_profit + ss_agg.ss_total_net_profit) > (SELECT AVG(total_net_profit) FROM cs_agg)
