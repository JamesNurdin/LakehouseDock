WITH cat_store_ret AS (
    SELECT
        d.d_year AS year,
        i.i_item_id AS item_id,
        w.w_warehouse_name AS warehouse_name,
        s.s_store_name AS store_name,
        'catalog_return' AS metric_type,
        SUM(cr.cr_return_amount) AS metric_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    GROUP BY d.d_year, i.i_item_id, w.w_warehouse_name, s.s_store_name
),
web_activity AS (
    SELECT
        d_sold.d_year AS year,
        i.i_item_id AS item_id,
        w.w_warehouse_name AS warehouse_name,
        CAST(NULL AS varchar) AS store_name,
        'web_sale' AS metric_type,
        SUM(ws.ws_ext_sales_price) AS metric_amount
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY d_sold.d_year, i.i_item_id, w.w_warehouse_name
)
SELECT year,
       item_id,
       warehouse_name,
       store_name,
       metric_type,
       metric_amount
FROM cat_store_ret
UNION ALL
SELECT year,
       item_id,
       warehouse_name,
       store_name,
       metric_type,
       metric_amount
FROM web_activity
ORDER BY year DESC,
         item_id
LIMIT 100
