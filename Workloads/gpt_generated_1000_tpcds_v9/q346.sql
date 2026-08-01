WITH RECURSIVE hour_values (time_sk, hour) AS (
    SELECT t.t_time_sk, t.t_hour
    FROM time_dim t
    WHERE t.t_hour = 0
    UNION ALL
    SELECT t.t_time_sk, t.t_hour
    FROM time_dim t
    JOIN hour_values hv
      ON t.t_hour = hv.hour + 1
    WHERE t.t_hour <= 5
)
SELECT
    cc.cc_name,
    ws_site.web_class,
    i_cs.i_brand,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(ws_cust_stats.distinct_bill_cust) AS total_distinct_web_customers,
    COUNT(*) AS total_transactions
FROM hour_values hv
JOIN catalog_sales cs
    ON cs.cs_sold_time_sk = hv.time_sk
JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i_cs
    ON cs.cs_item_sk = i_cs.i_item_sk
JOIN customer_demographics cd_bill_cs
    ON cs.cs_bill_cdemo_sk = cd_bill_cs.cd_demo_sk
JOIN customer_demographics cd_ship_cs
    ON cs.cs_ship_cdemo_sk = cd_ship_cs.cd_demo_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = hv.time_sk
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN item i_ws
    ON ws.ws_item_sk = i_ws.i_item_sk
JOIN customer_demographics cd_bill_ws
    ON ws.ws_bill_cdemo_sk = cd_bill_ws.cd_demo_sk
JOIN customer_demographics cd_ship_ws
    ON ws.ws_ship_cdemo_sk = cd_ship_ws.cd_demo_sk
LEFT JOIN LATERAL (
    SELECT COUNT(DISTINCT ws2.ws_bill_customer_sk) AS distinct_bill_cust
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = i_ws.i_item_sk
) AS ws_cust_stats ON TRUE
WHERE cs.cs_ext_wholesale_cost > 3500
  AND cd_bill_cs.cd_credit_rating = 'High Risk'
  AND ws_site.web_class = 'Unknown'
GROUP BY ROLLUP (cc.cc_name, ws_site.web_class, i_cs.i_brand)
ORDER BY total_catalog_profit DESC
LIMIT 100
