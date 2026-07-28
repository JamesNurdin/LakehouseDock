WITH catalog_data AS (
    SELECT
        i.i_category,
        i.i_brand,
        cs.cs_net_profit - COALESCE(cr.cr_net_loss, 0) AS net_profit,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                               AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        i.i_units = 'Lb'
        AND i.i_manufact_id IN (220, 294)
        AND hd.hd_income_band_sk BETWEEN 5 AND 15
        AND cc.cc_zip = '26534'
        AND w.w_state = 'CA'
        AND td.t_hour BETWEEN 9 AND 17
),
store_data AS (
    SELECT
        i.i_category,
        i.i_brand,
        ss.ss_net_profit AS net_profit,
        'store' AS channel
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE
        i.i_units = 'Lb'
        AND i.i_manufact_id IN (220, 294)
        AND hd.hd_income_band_sk BETWEEN 5 AND 15
        AND s.s_state = 'CA'
        AND td.t_hour BETWEEN 9 AND 17
),
web_data AS (
    SELECT
        i.i_category,
        i.i_brand,
        ws.ws_net_profit AS net_profit,
        'web' AS channel
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                               AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        i.i_units = 'Lb'
        AND i.i_manufact_id IN (220, 294)
        AND hd.hd_income_band_sk BETWEEN 5 AND 15
        AND w.w_state = 'CA'
        AND td.t_hour BETWEEN 9 AND 17
),
combined AS (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
),
agg AS (
    SELECT
        i_category,
        i_brand,
        channel,
        SUM(net_profit) AS total_profit
    FROM combined
    GROUP BY i_category, i_brand, channel
)
SELECT
    i_category,
    i_brand,
    channel,
    total_profit,
    AVG(total_profit) OVER (PARTITION BY i_category) AS avg_profit_by_category
FROM agg
WHERE total_profit > 5000
ORDER BY total_profit DESC
LIMIT 100
