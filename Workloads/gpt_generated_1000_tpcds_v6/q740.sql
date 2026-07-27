WITH base AS (
    SELECT
        time_dim.t_time_id,
        promotion.p_promo_name,
        warehouse.w_warehouse_name,
        warehouse.w_warehouse_sk,
        SUM(store_sales.ss_net_profit) AS store_profit,
        SUM(web_sales.ws_net_profit) AS web_profit,
        COUNT(DISTINCT store_returns.sr_ticket_number) AS return_cnt,
        (
            SELECT SUM(i.inv_quantity_on_hand)
            FROM inventory i
            WHERE i.inv_warehouse_sk = warehouse.w_warehouse_sk
        ) AS inventory_qty
    FROM store_sales
    JOIN time_dim
        ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
    JOIN promotion
        ON store_sales.ss_promo_sk = promotion.p_promo_sk
    LEFT JOIN store_returns
        ON store_returns.sr_item_sk = store_sales.ss_item_sk
        AND store_returns.sr_ticket_number = store_sales.ss_ticket_number
    JOIN web_sales
        ON web_sales.ws_sold_time_sk = time_dim.t_time_sk
        AND web_sales.ws_promo_sk = promotion.p_promo_sk
    JOIN web_page
        ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
    JOIN web_site
        ON web_sales.ws_web_site_sk = web_site.web_site_sk
    JOIN warehouse
        ON web_sales.ws_warehouse_sk = warehouse.w_warehouse_sk
    WHERE time_dim.t_meal_time = 'lunch'
      AND time_dim.t_time_sk IN (10, 16)
      AND promotion.p_discount_active = 'Y'
      AND warehouse.w_zip = '36098'
      AND EXISTS (
          SELECT 1
          FROM store_returns r
          WHERE r.sr_item_sk = store_sales.ss_item_sk
            AND r.sr_ticket_number = store_sales.ss_ticket_number
            AND r.sr_refunded_cash > 100
      )
    GROUP BY
        time_dim.t_time_id,
        promotion.p_promo_name,
        warehouse.w_warehouse_name,
        warehouse.w_warehouse_sk
)
SELECT
    t_time_id,
    p_promo_name,
    w_warehouse_name,
    store_profit,
    web_profit,
    inventory_qty,
    return_cnt,
    (store_profit + web_profit) AS total_profit,
    RANK() OVER (PARTITION BY p_promo_name ORDER BY (store_profit + web_profit) DESC) AS profit_rank
FROM base
ORDER BY total_profit DESC
LIMIT 100
