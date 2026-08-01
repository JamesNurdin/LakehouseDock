WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
)
SELECT
    s.s_store_name,
    cc.cc_name,
    sm.sm_type,
    ds.d_year,
    ds.d_month_seq,
    SUM(fs.cs_net_profit) AS total_net_profit,
    COUNT(fs.cs_order_number) AS orders_count,
    AVG(fs.cs_quantity) AS avg_quantity,
    (
        SELECT AVG(cs_net_profit)
        FROM filtered_sales
    ) AS overall_avg_net_profit
FROM filtered_sales fs
JOIN date_dim ds ON fs.cs_sold_date_sk = ds.d_date_sk
JOIN date_dim dsh ON fs.cs_ship_date_sk = dsh.d_date_sk
JOIN customer_demographics cd_bill ON fs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON fs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN call_center cc ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim dcc_open ON cc.cc_open_date_sk = dcc_open.d_date_sk
JOIN date_dim dcc_closed ON cc.cc_closed_date_sk = dcc_closed.d_date_sk
JOIN ship_mode sm ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s ON s.s_closed_date_sk = dsh.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = dsh.d_date_sk
JOIN web_page wp1 ON wp1.wp_creation_date_sk = dsh.d_date_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_page wp2
    WHERE wp2.wp_access_date_sk = fs.cs_sold_date_sk
      AND wp2.wp_type = 'Review'
)
  AND cd_bill.cd_dep_college_count >= 2
  AND cd_ship.cd_dep_employed_count >= 1
GROUP BY
    s.s_store_name,
    cc.cc_name,
    sm.sm_type,
    ds.d_year,
    ds.d_month_seq
ORDER BY
    total_net_profit DESC
LIMIT 100
