WITH
    catalog_sales_data AS (
        SELECT
            cs.cs_item_sk AS item_sk,
            cs.cs_order_number AS order_number,
            cs.cs_quantity AS quantity,
            cs.cs_net_paid AS net_paid,
            cs.cs_net_profit AS net_profit,
            cs.cs_bill_addr_sk AS bill_addr_sk,
            cs.cs_ship_mode_sk AS ship_mode_sk,
            cs.cs_promo_sk AS promo_sk,
            cs.cs_sold_date_sk AS sold_date_sk,
            CAST(NULL AS integer) AS web_page_sk
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450250
          AND EXISTS (
              SELECT 1
              FROM promotion p2
              WHERE p2.p_promo_sk = cs.cs_promo_sk
                AND p2.p_channel_email = 'Y'
          )
    ),
    web_sales_data AS (
        SELECT
            ws.ws_item_sk AS item_sk,
            ws.ws_order_number AS order_number,
            ws.ws_quantity AS quantity,
            ws.ws_net_paid AS net_paid,
            ws.ws_net_profit AS net_profit,
            ws.ws_bill_addr_sk AS bill_addr_sk,
            ws.ws_ship_mode_sk AS ship_mode_sk,
            ws.ws_promo_sk AS promo_sk,
            ws.ws_sold_date_sk AS sold_date_sk,
            ws.ws_web_page_sk AS web_page_sk
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450250
          AND wp.wp_type = 'content'
    ),
    combined_sales AS (
        SELECT
            item_sk,
            order_number,
            quantity,
            net_paid,
            net_profit,
            bill_addr_sk,
            ship_mode_sk,
            promo_sk,
            sold_date_sk,
            web_page_sk
        FROM catalog_sales_data
        UNION ALL
        SELECT
            item_sk,
            order_number,
            quantity,
            net_paid,
            net_profit,
            bill_addr_sk,
            ship_mode_sk,
            promo_sk,
            sold_date_sk,
            web_page_sk
        FROM web_sales_data
    ),
    sales_and_returns_items AS (
        SELECT DISTINCT cs.item_sk
        FROM combined_sales cs
        INTERSECT
        SELECT DISTINCT sr.sr_item_sk
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE sr.sr_return_quantity > 0
    ),
    aggregated_metrics AS (
        SELECT
            i.i_item_id,
            i.i_product_name,
            i.i_brand,
            p.p_promo_name,
            sm.sm_type AS ship_mode_type,
            COUNT(DISTINCT cs.order_number) AS order_cnt,
            SUM(cs.quantity) AS total_quantity,
            SUM(cs.net_paid) AS total_net_paid,
            SUM(cs.net_profit) AS total_net_profit,
            AVG(cs.net_paid) AS avg_net_paid,
            MAX(cs.net_paid) AS max_net_paid,
            MIN(cs.net_paid) AS min_net_paid,
            CASE
                WHEN p.p_discount_active = 'Y' THEN 'Active'
                ELSE 'Inactive'
            END AS promo_status,
            p.p_discount_active
        FROM combined_sales cs
        JOIN item i ON cs.item_sk = i.i_item_sk
        JOIN promotion p ON cs.promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON cs.ship_mode_sk = sm.sm_ship_mode_sk
        WHERE cs.item_sk IN (SELECT item_sk FROM sales_and_returns_items)
          AND NOT EXISTS (
              SELECT 1
              FROM catalog_returns cr
              WHERE cr.cr_item_sk = cs.item_sk
                AND cr.cr_return_amount > 1000
          )
        GROUP BY
            i.i_item_id,
            i.i_product_name,
            i.i_brand,
            p.p_promo_name,
            sm.sm_type,
            CASE
                WHEN p.p_discount_active = 'Y' THEN 'Active'
                ELSE 'Inactive'
            END,
            p.p_discount_active
    )
SELECT
    am.i_item_id,
    am.i_product_name,
    am.i_brand,
    am.promo_status,
    am.ship_mode_type,
    am.order_cnt,
    am.total_quantity,
    am.total_net_paid,
    am.total_net_profit,
    am.avg_net_paid,
    am.max_net_paid,
    am.min_net_paid,
    ROW_NUMBER() OVER (PARTITION BY am.i_brand ORDER BY am.total_net_profit DESC) AS brand_profit_rank
FROM aggregated_metrics am
ORDER BY am.total_net_profit DESC
LIMIT 100
