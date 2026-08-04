WITH ws_filtered AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_bill_addr_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk
    FROM web_sales ws
    WHERE ws.ws_net_profit > 0
      AND ws.ws_quantity >= 1
      AND ws.ws_sold_time_sk IS NOT NULL
)
SELECT
    wp.wp_web_page_id,
    td.t_hour,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt,
    CASE
        WHEN ib.ib_upper_bound <= 50000 THEN 'Low'
        WHEN ib.ib_upper_bound BETWEEN 50001 AND 100000 THEN 'Medium'
        ELSE 'High'
    END AS income_category,
    RANK() OVER (PARTITION BY wp.wp_type ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank_by_type,
    LAG(SUM(ws.ws_net_profit)) OVER (PARTITION BY wp.wp_type ORDER BY td.t_hour) AS lag_profit_by_hour
FROM ws_filtered ws
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs
    ON cs.cs_sold_time_sk = td.t_time_sk
WHERE ca.ca_location_type = 'apartment'
  AND cd.cd_gender = 'M'
  AND td.t_hour BETWEEN 8 AND 20
GROUP BY
    wp.wp_web_page_id,
    td.t_hour,
    ib.ib_upper_bound,
    wp.wp_type
ORDER BY total_net_profit DESC
LIMIT 100
