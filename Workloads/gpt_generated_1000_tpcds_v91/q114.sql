WITH catalog_sales_data AS (
    SELECT
        cs.cs_ship_date_sk AS sale_date_key,
        CAST('catalog' AS varchar) AS sales_type,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        (
            SELECT COUNT(*)
            FROM store_returns sr
            WHERE sr.sr_returned_date_sk = cs.cs_ship_date_sk
        ) AS return_count,
        ROW_NUMBER() OVER (
            PARTITION BY CAST('catalog' AS varchar)
            ORDER BY cs.cs_net_paid DESC
        ) AS sales_rank
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND cs.cs_quantity > 1
      AND cs.cs_net_paid > 0
),
web_sales_data AS (
    SELECT
        ws.ws_sold_date_sk AS sale_date_key,
        CAST('web' AS varchar) AS sales_type,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        (
            SELECT COUNT(*)
            FROM web_returns wr
            WHERE wr.wr_returned_date_sk = ws.ws_sold_date_sk
        ) AS return_count,
        ROW_NUMBER() OVER (
            PARTITION BY CAST('web' AS varchar)
            ORDER BY ws.ws_net_paid DESC
        ) AS sales_rank
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE wp.wp_type = 'search'
      AND ws.ws_quantity > 1
      AND ws.ws_net_paid > 0
)
SELECT
    sale_date_key,
    sales_type,
    net_paid,
    net_profit,
    return_count,
    sales_rank
FROM catalog_sales_data
UNION ALL
SELECT
    sale_date_key,
    sales_type,
    net_paid,
    net_profit,
    return_count,
    sales_rank
FROM web_sales_data
LIMIT 100
