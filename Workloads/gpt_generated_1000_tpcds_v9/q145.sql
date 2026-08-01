WITH shoes_base AS (
    SELECT
        item.i_item_id,
        item.i_category,
        warehouse.w_warehouse_id,
        warehouse.w_warehouse_name,
        web_site.web_name,
        SUM(web_sales.ws_ext_sales_price) AS total_sales,
        SUM(web_sales.ws_net_profit) AS total_profit,
        SUM(web_returns.wr_return_amt) AS total_returns,
        MAX(inventory.inv_quantity_on_hand) AS inventory_on_hand,
        CASE WHEN promotion.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_flag,
        promotion.p_discount_active
    FROM web_sales
    INNER JOIN item ON web_sales.ws_item_sk = item.i_item_sk
    INNER JOIN web_site ON web_sales.ws_web_site_sk = web_site.web_site_sk
    INNER JOIN warehouse ON web_sales.ws_warehouse_sk = warehouse.w_warehouse_sk
    INNER JOIN promotion ON web_sales.ws_promo_sk = promotion.p_promo_sk
    INNER JOIN web_returns ON web_returns.wr_item_sk = web_sales.ws_item_sk
        AND web_returns.wr_order_number = web_sales.ws_order_number
    INNER JOIN inventory ON inventory.inv_item_sk = item.i_item_sk
        AND inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
    WHERE item.i_category = 'Shoes'
      AND warehouse.w_county = 'Marshall County'
      AND promotion.p_response_target = 1
    GROUP BY
        item.i_item_id,
        item.i_category,
        warehouse.w_warehouse_id,
        warehouse.w_warehouse_name,
        web_site.web_name,
        promotion.p_discount_active
),
shoes_ranked AS (
    SELECT
        i_item_id,
        i_category,
        w_warehouse_id,
        w_warehouse_name,
        web_name,
        total_sales,
        total_profit,
        total_returns,
        inventory_on_hand,
        promo_flag,
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY total_profit DESC) AS profit_rank
    FROM shoes_base
),
electronics_base AS (
    SELECT
        item.i_item_id,
        item.i_category,
        warehouse.w_warehouse_id,
        warehouse.w_warehouse_name,
        web_site.web_name,
        SUM(web_sales.ws_ext_sales_price) AS total_sales,
        SUM(web_sales.ws_net_profit) AS total_profit,
        SUM(web_returns.wr_return_amt) AS total_returns,
        MAX(inventory.inv_quantity_on_hand) AS inventory_on_hand,
        CASE WHEN promotion.p_channel_email = 'N' THEN 1 ELSE 0 END AS promo_flag,
        promotion.p_channel_email
    FROM web_sales
    INNER JOIN item ON web_sales.ws_item_sk = item.i_item_sk
    INNER JOIN web_site ON web_sales.ws_web_site_sk = web_site.web_site_sk
    INNER JOIN warehouse ON web_sales.ws_warehouse_sk = warehouse.w_warehouse_sk
    INNER JOIN promotion ON web_sales.ws_promo_sk = promotion.p_promo_sk
    INNER JOIN web_returns ON web_returns.wr_item_sk = web_sales.ws_item_sk
        AND web_returns.wr_order_number = web_sales.ws_order_number
    INNER JOIN inventory ON inventory.inv_item_sk = item.i_item_sk
        AND inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
    WHERE item.i_category = 'Electronics'
      AND warehouse.w_county = 'Walker County'
      AND promotion.p_channel_email = 'N'
    GROUP BY
        item.i_item_id,
        item.i_category,
        warehouse.w_warehouse_id,
        warehouse.w_warehouse_name,
        web_site.web_name,
        promotion.p_channel_email
),
electronics_ranked AS (
    SELECT
        i_item_id,
        i_category,
        w_warehouse_id,
        w_warehouse_name,
        web_name,
        total_sales,
        total_profit,
        total_returns,
        inventory_on_hand,
        promo_flag,
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY total_profit DESC) AS profit_rank
    FROM electronics_base
)
SELECT
    i_item_id,
    i_category,
    w_warehouse_id,
    w_warehouse_name,
    web_name,
    total_sales,
    total_profit,
    total_returns,
    inventory_on_hand,
    promo_flag,
    profit_rank
FROM shoes_ranked
UNION ALL
SELECT
    i_item_id,
    i_category,
    w_warehouse_id,
    w_warehouse_name,
    web_name,
    total_sales,
    total_profit,
    total_returns,
    inventory_on_hand,
    promo_flag,
    profit_rank
FROM electronics_ranked
ORDER BY total_profit DESC, profit_rank ASC
LIMIT 100
