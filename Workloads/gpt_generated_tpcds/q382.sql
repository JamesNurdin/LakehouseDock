WITH catalog_sales_promo AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_promo_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
),
web_sales_promo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_warehouse_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_promo_sk
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
),
sales_combined AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales_promo cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_warehouse_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_promo_sk
    FROM web_sales_promo ws
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    ds_start.d_date AS promo_start_date,
    ds_end.d_date AS promo_end_date,
    i.i_category,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.net_profit) AS total_net_profit
FROM sales_combined s
JOIN promotion p ON s.promo_sk = p.p_promo_sk
JOIN date_dim ds_start ON p.p_start_date_sk = ds_start.d_date_sk
JOIN date_dim ds_end ON p.p_end_date_sk = ds_end.d_date_sk
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_date BETWEEN ds_start.d_date AND ds_end.d_date
  AND ds_start.d_year = 2000
GROUP BY p.p_promo_id, p.p_promo_name, ds_start.d_date, ds_end.d_date, i.i_category
ORDER BY total_net_profit DESC
LIMIT 100
