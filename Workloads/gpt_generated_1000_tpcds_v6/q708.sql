WITH store_agg AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_brand AS i_brand,
        t.t_hour AS t_hour,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_radio = 'N'
      AND t.t_shift = 'first'
    GROUP BY i.i_item_id, i.i_brand, t.t_hour
),
web_agg AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_brand AS i_brand,
        t.t_hour AS t_hour,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_radio = 'N'
      AND t.t_shift = 'first'
    GROUP BY i.i_item_id, i.i_brand, t.t_hour
)
SELECT
    combined.item_id,
    combined.brand,
    combined.hour,
    SUM(combined.total_quantity) AS quantity,
    SUM(combined.total_sales) AS sales,
    SUM(combined.total_profit) AS profit
FROM (
    SELECT
        i_item_id AS item_id,
        i_brand AS brand,
        t_hour AS hour,
        total_quantity,
        total_sales,
        total_profit
    FROM store_agg
    UNION ALL
    SELECT
        i_item_id AS item_id,
        i_brand AS brand,
        t_hour AS hour,
        total_quantity,
        total_sales,
        total_profit
    FROM web_agg
) AS combined
GROUP BY GROUPING SETS (
    (item_id, brand, hour),
    (item_id, brand),
    (brand, hour),
    (brand),
    ()
)
ORDER BY quantity DESC
LIMIT 100
