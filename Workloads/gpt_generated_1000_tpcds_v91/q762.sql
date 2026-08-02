WITH ws_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_warehouse_sk,
        hd.hd_income_band_sk,
        sm.sm_type,
        w.w_warehouse_name,
        wp.wp_type AS page_type,
        site.web_name AS site_name
    FROM web_sales ws
    INNER JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450830 AND 2450840
      AND ws.ws_ext_sales_price > 100
      AND wp.wp_type = 'home'
      AND EXISTS (
          SELECT 1
          FROM inventory i
          WHERE i.inv_warehouse_sk = ws.ws_warehouse_sk
            AND i.inv_quantity_on_hand > 500
      )
),
cr_base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_warehouse_sk,
        hd.hd_income_band_sk,
        sm.sm_type,
        w.w_warehouse_name
    FROM catalog_returns cr
    INNER JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    INNER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 0
      AND sm.sm_carrier = 'UPS'
      AND cr.cr_returned_date_sk BETWEEN 2450830 AND 2450840
)
SELECT *
FROM (
    SELECT DISTINCT
        ws.ws_order_number               AS order_id,
        ws.ws_sold_date_sk               AS date_key,
        ws.ws_quantity                   AS qty,
        ws.ws_ext_sales_price            AS sales_price,
        CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
        ws.hd_income_band_sk             AS income_band,
        ws.sm_type                       AS ship_type,
        ws.w_warehouse_name              AS warehouse,
        ws.page_type                     AS page_type,
        ws.site_name                     AS site_name,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_warehouse_sk ORDER BY ws.ws_ext_sales_price DESC) AS row_num,
        (SELECT sum(i.inv_quantity_on_hand)
         FROM inventory i
         WHERE i.inv_warehouse_sk = ws.ws_warehouse_sk) AS total_inventory_qty,
        'WEB'                            AS source
    FROM ws_base ws
) ws_sel

UNION

SELECT *
FROM (
    SELECT DISTINCT
        cr.cr_order_number               AS order_id,
        cr.cr_returned_date_sk           AS date_key,
        -cr.cr_return_quantity           AS qty,
        cr.cr_return_amount              AS sales_price,
        CASE WHEN cr.cr_net_loss > 0 THEN 'LOSS' ELSE 'PROFIT' END AS profit_flag,
        cr.hd_income_band_sk             AS income_band,
        cr.sm_type                       AS ship_type,
        cr.w_warehouse_name              AS warehouse,
        CAST(NULL AS varchar)            AS page_type,
        CAST(NULL AS varchar)            AS site_name,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_warehouse_sk ORDER BY cr.cr_return_amount DESC) AS row_num,
        (SELECT sum(i.inv_quantity_on_hand)
         FROM inventory i
         WHERE i.inv_warehouse_sk = cr.cr_warehouse_sk) AS total_inventory_qty,
        'RETURN'                         AS source
    FROM cr_base cr
) cr_sel
ORDER BY date_key, order_id
