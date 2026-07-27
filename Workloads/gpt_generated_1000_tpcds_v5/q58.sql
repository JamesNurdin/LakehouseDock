WITH sales_returns AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        td.t_hour,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(cr.cr_return_amount) AS total_returns_amount,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 0
            THEN SUM(cs.cs_ext_sales_price) / SUM(ws.ws_ext_sales_price)
            ELSE NULL
        END AS catalog_to_web_sales_ratio
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND sm.sm_carrier = 'FEDEX'
      AND i.i_current_price BETWEEN 30 AND 200
      AND cs.cs_quantity > 1
      AND ws.ws_net_profit > 0
      AND cr.cr_return_quantity >= 0
      AND wp.wp_type = 'order'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        td.t_hour
)
SELECT
    carrier,
    hour,
    SUM(total_catalog_sales) AS sum_catalog_sales,
    SUM(total_web_sales) AS sum_web_sales,
    AVG(catalog_to_web_sales_ratio) AS avg_sales_ratio,
    CASE WHEN SUM(total_returns_amount) > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_flag
FROM (
    SELECT
        sm_carrier AS carrier,
        t_hour AS hour,
        total_catalog_sales,
        total_web_sales,
        total_returns_amount,
        catalog_to_web_sales_ratio
    FROM sales_returns
) sr
GROUP BY GROUPING SETS (
    (carrier, hour),
    (carrier),
    (hour),
    ()
)
ORDER BY carrier, hour
LIMIT 100
