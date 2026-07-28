WITH catalog_agg AS (
    SELECT
        i.i_item_id AS item_id,
        td.t_hour AS hour_of_day,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound BETWEEN 30000 AND 80000
      AND td.t_hour BETWEEN 8 AND 20
      AND i.i_brand_id = 5
    GROUP BY i.i_item_id, td.t_hour
    HAVING SUM(cs.cs_quantity) > 100
),
web_agg AS (
    SELECT
        i.i_item_id AS item_id,
        td.t_hour AS hour_of_day,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound BETWEEN 30000 AND 80000
      AND td.t_hour BETWEEN 8 AND 20
      AND i.i_brand_id = 5
    GROUP BY i.i_item_id, td.t_hour
    HAVING SUM(ws.ws_quantity) > 100
)
SELECT
    item_id,
    hour_of_day,
    channel,
    total_net_profit,
    total_quantity
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
) AS combined
ORDER BY total_net_profit DESC
LIMIT 100
