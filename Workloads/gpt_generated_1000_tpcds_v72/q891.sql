WITH
    ws_agg AS (
        SELECT
            ws.ws_warehouse_sk,
            d_year.d_year,
            SUM(ws.ws_net_profit) AS total_net_profit
        FROM web_sales ws
        JOIN date_dim d_year ON ws.ws_sold_date_sk = d_year.d_date_sk
        GROUP BY ws.ws_warehouse_sk, d_year.d_year
    ),
    cr_agg AS (
        SELECT
            cr.cr_warehouse_sk,
            d_year.d_year,
            SUM(cr.cr_net_loss) AS total_net_loss
        FROM catalog_returns cr
        JOIN date_dim d_year ON cr.cr_returned_date_sk = d_year.d_date_sk
        GROUP BY cr.cr_warehouse_sk, d_year.d_year
    ),
    inv_avg AS (
        SELECT
            inv.inv_warehouse_sk,
            d_year.d_year,
            AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand
        FROM inventory inv
        JOIN date_dim d_year ON inv.inv_date_sk = d_year.d_date_sk
        GROUP BY inv.inv_warehouse_sk, d_year.d_year
    ),
    ws_site_agg AS (
        SELECT
            ws.ws_warehouse_sk,
            ws.ws_web_site_sk,
            d_year.d_year,
            SUM(ws.ws_ext_sales_price) AS total_sales_amount
        FROM web_sales ws
        JOIN date_dim d_year ON ws.ws_sold_date_sk = d_year.d_date_sk
        GROUP BY ws.ws_warehouse_sk, ws.ws_web_site_sk, d_year.d_year
    ),
    inv_sum AS (
        SELECT
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        GROUP BY inv_warehouse_sk
    )
SELECT
    w.w_warehouse_name,
    ws_agg.d_year AS sales_year,
    ws_agg.total_net_profit,
    cr_agg.total_net_loss,
    CASE WHEN ws_agg.total_net_profit > cr_agg.total_net_loss
         THEN 'Profit > Loss'
         ELSE 'Loss >= Profit'
    END AS profit_status,
    inv_avg.avg_qty_on_hand,
    ws_site_agg.total_sales_amount,
    ws_site.web_name,
    d_open.d_date AS site_open_date,
    d_close.d_date AS site_close_date,
    inv_sum.total_qty_on_hand
FROM warehouse w
JOIN ws_agg ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN cr_agg ON cr_agg.cr_warehouse_sk = w.w_warehouse_sk AND cr_agg.d_year = ws_agg.d_year
JOIN inv_avg ON inv_avg.inv_warehouse_sk = w.w_warehouse_sk AND inv_avg.d_year = ws_agg.d_year
JOIN ws_site_agg ON ws_site_agg.ws_warehouse_sk = w.w_warehouse_sk AND ws_site_agg.d_year = ws_agg.d_year
JOIN web_site ws_site ON ws_site_agg.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim d_open ON ws_site.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close ON ws_site.web_close_date_sk = d_close.d_date_sk
JOIN inv_sum ON inv_sum.inv_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (SELECT 1 FROM inventory inv_check
              WHERE inv_check.inv_warehouse_sk = w.w_warehouse_sk
                AND inv_check.inv_quantity_on_hand > 1000)
ORDER BY ws_agg.total_net_profit DESC, ws_agg.d_year
LIMIT 100
