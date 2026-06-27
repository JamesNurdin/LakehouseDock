WITH sales_union AS (
    SELECT
        ss.ss_sold_date_sk AS sale_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_moy,
        ss.ss_item_sk AS item_sk,
        i.i_item_id,
        i.i_product_name,
        ss.ss_quantity AS quantity,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2022

    UNION ALL

    SELECT
        ws.ws_sold_date_sk AS sale_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_moy,
        ws.ws_item_sk AS item_sk,
        i.i_item_id,
        i.i_product_name,
        ws.ws_quantity AS quantity,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
),
sales_monthly AS (
    SELECT
        d_year,
        d_month_seq,
        d_moy,
        item_sk,
        i_item_id,
        i_product_name,
        SUM(quantity) AS total_quantity_sold,
        SUM(net_profit) AS total_net_profit,
        SUM(discount_amt) AS total_discount_amt
    FROM sales_union
    GROUP BY d_year, d_month_seq, d_moy, item_sk, i_item_id, i_product_name
),
inventory_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_moy,
        inv.inv_item_sk AS item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY d.d_year, d.d_month_seq, d.d_moy, inv.inv_item_sk, i.i_item_id, i.i_product_name
)
SELECT
    sm.d_year,
    sm.d_moy AS month,
    sm.i_item_id,
    sm.i_product_name,
    sm.total_quantity_sold,
    sm.total_net_profit,
    sm.total_discount_amt / NULLIF(sm.total_quantity_sold, 0) AS avg_discount_per_unit,
    im.total_inventory_qty
FROM sales_monthly sm
LEFT JOIN inventory_monthly im
    ON sm.d_year = im.d_year
    AND sm.d_month_seq = im.d_month_seq
    AND sm.item_sk = im.item_sk
ORDER BY sm.total_net_profit DESC
LIMIT 10
