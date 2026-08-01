WITH agg_sales AS (
    SELECT
        ca.ca_state AS state,
        td.t_meal_time AS meal_time,
        'store' AS sales_channel,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        CASE
            WHEN SUM(ss.ss_net_profit) > 100000 THEN 'High'
            WHEN SUM(ss.ss_net_profit) BETWEEN 0 AND 100000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ib.ib_upper_bound >= 150000
      AND cd.cd_education_status = 'College'
    GROUP BY ca.ca_state, td.t_meal_time

    UNION ALL

    SELECT
        ca.ca_state AS state,
        td.t_meal_time AS meal_time,
        'web' AS sales_channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        CASE
            WHEN SUM(ws.ws_net_profit) > 100000 THEN 'High'
            WHEN SUM(ws.ws_net_profit) BETWEEN 0 AND 100000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ib.ib_upper_bound >= 150000
      AND cd.cd_education_status = 'College'
    GROUP BY ca.ca_state, td.t_meal_time
)
SELECT
    a.state,
    a.meal_time,
    a.sales_channel,
    a.total_net_paid,
    a.total_discount,
    a.profit_category
FROM agg_sales a
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    JOIN customer_address ca2 ON ss.ss_addr_sk = ca2.ca_address_sk
    JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    WHERE ca2.ca_state = a.state
      AND ib2.ib_upper_bound >= 200000
)
ORDER BY a.state, a.meal_time, a.sales_channel
LIMIT 100
