WITH store_agg AS (
    SELECT d.d_year,
           d.d_month_seq AS month,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(ss.ss_net_profit) AS store_net_profit,
           SUM(ss.ss_ext_sales_price) AS store_sales,
           COUNT(*) AS store_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_shift = 'Morning'
      AND d.d_year BETWEEN 2000 AND 2003
      AND cd.cd_purchase_estimate > 1500
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender, cd.cd_marital_status
),
web_agg AS (
    SELECT d.d_year,
           d.d_month_seq AS month,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(ws.ws_net_profit) AS web_net_profit,
           SUM(ws.ws_ext_sales_price) AS web_sales,
           COUNT(*) AS web_transactions
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_shift = 'Morning'
      AND d.d_year BETWEEN 2000 AND 2003
      AND cd.cd_purchase_estimate > 1500
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender, cd.cd_marital_status
),
inventory_agg AS (
    SELECT d.d_year,
           d.d_month_seq AS month,
           SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2003
    GROUP BY d.d_year, d.d_month_seq
)
SELECT s.d_year,
       s.month,
       s.cd_gender,
       s.cd_marital_status,
       s.store_net_profit,
       w.web_net_profit,
       (s.store_net_profit + w.web_net_profit) AS total_profit,
       (s.store_sales + w.web_sales) AS total_sales,
       ((s.store_net_profit + w.web_net_profit) / NULLIF((s.store_sales + w.web_sales), 0)) * 100 AS profit_margin_pct,
       i.total_inventory_qty,
       RANK() OVER (PARTITION BY s.d_year ORDER BY ((s.store_net_profit + w.web_net_profit) / NULLIF((s.store_sales + w.web_sales), 0)) DESC) AS profit_rank
FROM store_agg s
JOIN web_agg w
  ON s.d_year = w.d_year
 AND s.month = w.month
 AND s.cd_gender = w.cd_gender
 AND s.cd_marital_status = w.cd_marital_status
JOIN inventory_agg i
  ON s.d_year = i.d_year
 AND s.month = i.month
WHERE (s.store_sales + w.web_sales) > 10000
ORDER BY profit_margin_pct DESC
LIMIT 100
