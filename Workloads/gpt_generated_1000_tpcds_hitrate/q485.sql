WITH
    cr AS (
        SELECT *
        FROM catalog_returns
    ),
    ws AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    cr_join AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            d.d_year AS return_year,
            hd_ref.hd_income_band_sk AS ref_income_band,
            hd_ret.hd_income_band_sk AS ret_income_band,
            w.w_warehouse_name AS warehouse_name
        FROM cr
        JOIN date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN warehouse w
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN household_demographics hd_ref
            ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
        JOIN household_demographics hd_ret
            ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    ),
    ws_join AS (
        SELECT
            ws.ws_order_number,
            ws.ws_quantity,
            ws.ws_net_paid,
            d.d_year AS sold_year,
            w2.w_warehouse_name AS warehouse_name,
            hd_bill.hd_dep_count AS bill_dep,
            hd_ship.hd_vehicle_count AS ship_vehicle,
            wp.wp_type,
            site.web_name
        FROM ws
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site site
            ON ws.ws_web_site_sk = site.web_site_sk
        RIGHT OUTER JOIN date_dim d
            ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN warehouse w2
            ON ws.ws_warehouse_sk = w2.w_warehouse_sk
        JOIN household_demographics hd_bill
            ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship
            ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    ),
    union_data AS (
        SELECT
            return_year AS yr,
            warehouse_name AS warehouse,
            cr_return_quantity AS qty,
            cr_return_amount AS amount,
            'return' AS src
        FROM cr_join
        UNION DISTINCT
        SELECT
            sold_year AS yr,
            warehouse_name AS warehouse,
            ws_quantity AS qty,
            ws_net_paid AS amount,
            'sale' AS src
        FROM ws_join
    )
SELECT
    yr,
    warehouse,
    src,
    SUM(qty) AS total_quantity,
    SUM(amount) AS total_amount,
    RANK() OVER (PARTITION BY src ORDER BY SUM(qty) DESC) AS qty_rank
FROM union_data
GROUP BY GROUPING SETS ((yr, warehouse, src), (src))
ORDER BY src, total_quantity DESC
LIMIT 100
