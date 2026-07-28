WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_id,
        w.w_state,
        p.p_promo_id,
        d_sold.d_year,
        SUM(ws.ws_quantity)                         AS total_qty,
        SUM(ws.ws_ext_sales_price)                  AS total_sales,
        SUM(ws.ws_net_profit)                       AS total_profit,
        AVG(ws.ws_ext_discount_amt)                AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number)          AS num_orders,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0)  AS total_inventory_on_sold_date
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site s
        ON ws.ws_web_site_sk = s.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND i.i_brand = 'Brand#12'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_id,
        w.w_state,
        p.p_promo_id,
        d_sold.d_year
)
SELECT
    sa.i_item_id,
    sa.i_product_name,
    sa.w_warehouse_id,
    sa.w_state,
    sa.p_promo_id,
    sa.total_qty,
    sa.total_sales,
    sa.total_profit,
    sa.avg_discount,
    sa.total_inventory_on_sold_date,
    (
        SELECT AVG(sa2.total_profit)
        FROM sales_agg sa2
        WHERE sa2.i_item_id = sa.i_item_id
    ) AS avg_item_profit_across_warehouses
FROM sales_agg sa
WHERE sa.total_profit > (
    SELECT AVG(total_profit)
    FROM sales_agg
)
ORDER BY sa.total_profit DESC
LIMIT 100
