WITH 
months AS (
    SELECT month_num
    FROM UNNEST(sequence(1, 12)) AS t(month_num)
),
channel_list AS (
    SELECT 'store' AS channel
    UNION ALL SELECT 'catalog'
    UNION ALL SELECT 'web'
),
sales_union AS (
    SELECT 
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_profit AS net_profit,
        'store' AS channel,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid
    FROM store_sales ss
    UNION ALL
    SELECT 
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    UNION ALL
    SELECT 
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_net_profit AS net_profit,
        'web' AS channel,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid
    FROM web_sales ws
),
monthly_sales AS (
    SELECT 
        d.d_year AS year,
        d.d_moy AS month_num,
        i.i_item_id,
        i.i_product_name,
        su.channel,
        SUM(su.net_profit) AS total_net_profit,
        SUM(su.quantity) AS total_quantity,
        SUM(su.net_paid) AS total_net_paid
    FROM sales_union su
    JOIN date_dim d ON su.date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_item_id, i.i_product_name, su.channel
),
returns_union AS (
    SELECT 
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel,
        cr.cr_return_quantity AS quantity
    FROM catalog_returns cr
    UNION ALL
    SELECT 
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_net_loss AS net_loss,
        'store' AS channel,
        sr.sr_return_quantity AS quantity
    FROM store_returns sr
    UNION ALL
    SELECT 
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_item_sk AS item_sk,
        wr.wr_net_loss AS net_loss,
        'web' AS channel,
        wr.wr_return_quantity AS quantity
    FROM web_returns wr
),
monthly_returns AS (
    SELECT 
        d.d_year AS year,
        d.d_moy AS month_num,
        i.i_item_id,
        i.i_product_name,
        ru.channel,
        SUM(ru.net_loss) AS total_net_loss,
        SUM(ru.quantity) AS total_return_quantity
    FROM returns_union ru
    JOIN date_dim d ON ru.date_sk = d.d_date_sk
    JOIN item i ON ru.item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_item_id, i.i_product_name, ru.channel
),
combined_sales AS (
    SELECT 
        ms.year,
        ms.month_num,
        ms.i_item_id,
        ms.i_product_name,
        ms.channel,
        ms.total_net_profit,
        COALESCE(mr.total_net_loss, 0) AS total_net_loss,
        ms.total_quantity,
        COALESCE(mr.total_return_quantity, 0) AS total_return_quantity,
        ms.total_net_paid,
        (ms.total_net_profit - COALESCE(mr.total_net_loss, 0)) AS net_profit_after_returns,
        (ms.total_quantity - COALESCE(mr.total_return_quantity, 0)) AS net_quantity_sold
    FROM monthly_sales ms
    LEFT JOIN monthly_returns mr 
        ON ms.year = mr.year
        AND ms.month_num = mr.month_num
        AND ms.i_item_id = mr.i_item_id
        AND ms.channel = mr.channel
),
all_scaffold AS (
    SELECT 
        m.month_num,
        i.i_item_id,
        i.i_product_name,
        cl.channel
    FROM months m
    CROSS JOIN (SELECT i_item_id, i_product_name FROM item) i
    CROSS JOIN channel_list cl
),
combined AS (
    SELECT 
        COALESCE(cs.year, 2001) AS year,
        sc.month_num,
        sc.i_item_id,
        sc.i_product_name,
        sc.channel,
        COALESCE(cs.total_net_profit, 0) AS total_net_profit,
        COALESCE(cs.total_net_loss, 0) AS total_net_loss,
        COALESCE(cs.total_quantity, 0) AS total_quantity,
        COALESCE(cs.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cs.total_net_paid, 0) AS total_net_paid,
        COALESCE(cs.net_profit_after_returns, 0) AS net_profit_after_returns,
        COALESCE(cs.net_quantity_sold, 0) AS net_quantity_sold
    FROM all_scaffold sc
    LEFT JOIN combined_sales cs 
        ON sc.month_num = cs.month_num
        AND sc.i_item_id = cs.i_item_id
        AND sc.channel = cs.channel
),
ranked AS (
    SELECT 
        c.*,
        ROW_NUMBER() OVER (PARTITION BY c.year, c.month_num, c.channel ORDER BY c.net_profit_after_returns DESC) AS rank_in_channel_month,
        SUM(c.net_profit_after_returns) OVER (PARTITION BY c.year, c.month_num) AS total_profit_all_channels,
        CASE 
            WHEN c.i_product_name IS NULL THEN 'UNKNOWN' 
            ELSE c.i_product_name 
        END AS product_name_clean
    FROM combined c
),
overall_year AS (
    SELECT 
        i.i_item_id,
        (SUM(su.net_profit) - COALESCE(SUM(ru.net_loss), 0)) AS year_net_profit
    FROM sales_union su
    LEFT JOIN returns_union ru 
        ON su.date_sk = ru.date_sk 
        AND su.item_sk = ru.item_sk 
        AND su.channel = ru.channel
    JOIN item i ON su.item_sk = i.i_item_sk
    JOIN date_dim d ON su.date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id
)
SELECT 
    r.year,
    r.month_num,
    r.channel,
    r.i_item_id,
    r.product_name_clean,
    r.net_profit_after_returns,
    r.total_quantity,
    r.total_return_quantity,
    r.total_net_paid,
    r.rank_in_channel_month,
    r.total_profit_all_channels,
    oy.year_net_profit,
    CONCAT(r.channel, ':', COALESCE(CAST(r.i_item_id AS VARCHAR), 'N/A')) AS channel_item_key,
    CASE 
        WHEN r.net_profit_after_returns > 0 AND r.total_quantity > 0 THEN 'POSITIVE' 
        WHEN r.net_profit_after_returns < 0 THEN 'NEGATIVE' 
        ELSE 'NEUTRAL' 
    END AS profit_category,
    CASE 
        WHEN r.rank_in_channel_month <= 3 AND r.net_profit_after_returns > 0.1 * r.total_profit_all_channels 
        THEN 'TOP3_HIGH_PROFIT' 
        ELSE NULL 
    END AS top_flag,
    (SELECT MAX(cs2.total_net_paid) FROM combined cs2 WHERE cs2.i_item_id = r.i_item_id) AS max_paid_for_item,
    (SELECT COUNT(DISTINCT cs3.month_num) FROM combined cs3 WHERE cs3.i_item_id = r.i_item_id AND cs3.net_quantity_sold > 0) AS months_sold,
    LOWER(r.product_name_clean) AS product_name_lower
FROM ranked r
JOIN overall_year oy ON r.i_item_id = oy.i_item_id
WHERE r.rank_in_channel_month <= 10
  AND (r.channel = 'store' 
       OR (r.channel = 'catalog' AND r.net_profit_after_returns > 1000) 
       OR (r.channel = 'web' AND r.net_profit_after_returns > 500))
UNION ALL
SELECT 
    2001 AS year,
    0 AS month_num,
    'ALL' AS channel,
    i.i_item_id,
    i.i_product_name,
    oy.year_net_profit,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    oy.year_net_profit,
    CONCAT('ALL:', CAST(i.i_item_id AS VARCHAR)) AS channel_item_key,
    CASE 
        WHEN oy.year_net_profit > 0 THEN 'POSITIVE' 
        ELSE 'NEGATIVE' 
    END AS profit_category,
    CASE 
        WHEN oy.year_net_profit > (SELECT MAX(year_net_profit) FROM overall_year) * 0.9 THEN 'TOP_OVERALL' 
        ELSE NULL 
    END AS top_flag,
    NULL,
    NULL,
    LOWER(i.i_product_name) AS product_name_lower
FROM overall_year oy
JOIN item i ON oy.i_item_id = i.i_item_id
WHERE oy.year_net_profit > 10000
ORDER BY year, month_num, channel, rank_in_channel_month
LIMIT 100
