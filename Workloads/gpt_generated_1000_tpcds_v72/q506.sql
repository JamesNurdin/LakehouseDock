WITH sales_union AS (
    SELECT
        d.d_date AS sale_date,
        d.d_date_sk AS d_date_sk,
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001

    UNION ALL

    SELECT
        d.d_date AS sale_date,
        d.d_date_sk AS d_date_sk,
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
)
SELECT
    su.sale_date,
    su.item_id,
    su.product_name,
    su.channel,
    SUM(su.net_profit) AS total_profit,
    SUM(su.quantity) AS total_quantity,
    CASE WHEN SUM(su.net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_level,
    (
        SELECT COUNT(*)
        FROM promotion p
        WHERE p.p_item_sk = su.item_sk
          AND p.p_start_date_sk <= su.d_date_sk
    ) AS promo_count,
    RANK() OVER (PARTITION BY su.sale_date ORDER BY SUM(su.net_profit) DESC) AS profit_rank
FROM sales_union su
GROUP BY
    su.sale_date,
    su.item_id,
    su.product_name,
    su.channel,
    su.d_date_sk,
    su.item_sk
ORDER BY
    su.sale_date,
    profit_rank
LIMIT 100
