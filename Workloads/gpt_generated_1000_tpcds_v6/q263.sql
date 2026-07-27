WITH joined_sales AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        i.i_rec_start_date,
        w.w_warehouse_name,
        p.p_promo_name
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
)
SELECT
    warehouse_name,
    promo_name,
    SUM(total_quantity) AS total_quantity,
    SUM(total_profit)   AS total_profit,
    sales_year
FROM (
    SELECT
        w_warehouse_name AS warehouse_name,
        p_promo_name   AS promo_name,
        ws_quantity    AS total_quantity,
        ws_net_profit  AS total_profit,
        '2000'         AS sales_year
    FROM joined_sales
    WHERE i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'

    UNION ALL

    SELECT
        w_warehouse_name AS warehouse_name,
        p_promo_name   AS promo_name,
        ws_quantity    AS total_quantity,
        ws_net_profit  AS total_profit,
        '2001'         AS sales_year
    FROM joined_sales
    WHERE i_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
) AS yearly_sales
GROUP BY warehouse_name, promo_name, sales_year
ORDER BY sales_year, total_profit DESC
