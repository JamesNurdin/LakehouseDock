/*
Goal: Identify the top selling items (by net paid) that were returned through stores and also appear in web sales,
including detailed store, item, and web context, while sampling items, applying realistic filters, and ranking the results.
*/
WITH sampled_items AS (
    SELECT *
    FROM item TABLESAMPLE BERNOULLI (10)
    WHERE i_rec_start_date > DATE '2001-01-01'
),
base AS (
    SELECT
        s.s_store_name,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        i.i_item_id,
        i.i_brand,
        ws.ws_quantity,
        SUM(ws.ws_net_paid)          AS total_net_paid,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        MIN(ws.ws_net_paid)          AS min_net_paid,
        MAX(ws.ws_net_paid)          AS max_net_paid
    FROM sampled_items i
    JOIN store_returns sr       ON sr.sr_item_sk = i.i_item_sk
    JOIN store s                ON s.s_store_sk = sr.sr_store_sk
    JOIN time_dim td            ON td.t_time_sk = sr.sr_return_time_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = sr.sr_hdemo_sk
    JOIN catalog_returns cr    ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc        ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN catalog_page cp       ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN ship_mode sm          ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    JOIN warehouse w           ON w.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN web_sales ws          ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site webs         ON webs.web_site_sk = ws.ws_web_site_sk
    JOIN web_page wp           ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_returns wr        ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk = i.i_item_sk
    WHERE
        td.t_hour = 14
        AND w.w_county = 'Richland County'
        AND wp.wp_autogen_flag = 'Y'
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = i.i_item_sk
              AND cr2.cr_returned_date_sk = ws.ws_sold_date_sk
        )
    GROUP BY
        s.s_store_name,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        i.i_item_id,
        i.i_brand,
        ws.ws_quantity
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS row_num,
    s_store_name,
    ws_order_number,
    ws_sold_date_sk,
    i_item_id,
    i_brand,
    ws_quantity,
    total_net_paid,
    avg_discount,
    order_cnt,
    min_net_paid,
    max_net_paid
FROM base
ORDER BY total_net_paid DESC
LIMIT 100
