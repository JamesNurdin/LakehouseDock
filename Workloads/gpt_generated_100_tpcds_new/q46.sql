WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    cc.cc_name,
    i.i_category,
    w.w_warehouse_name,
    inv_agg.total_qty_on_hand,
    SUM(ss.ss_ext_sales_price)            AS total_store_sales,
    SUM(ws.ws_ext_sales_price)            AS total_web_sales,
    SUM(cr.cr_return_amount)              AS total_catalog_returns,
    SUM(wr.wr_return_amt)                 AS total_web_returns
FROM inv_agg
JOIN item i                 ON inv_agg.inv_item_sk = i.i_item_sk
JOIN warehouse w            ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr    ON cr.cr_item_sk = i.i_item_sk
                            AND cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc        ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm          ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r               ON cr.cr_reason_sk = r.r_reason_sk
JOIN time_dim t_cr          ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN customer c            ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN store_sales ss        ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim t_ss          ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN web_sales ws          ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim t_ws          ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_returns wr        ON wr.wr_item_sk = i.i_item_sk
JOIN time_dim t_wr          ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN web_page wp           ON wp.wp_web_page_sk = ws.ws_web_page_sk
WHERE i.i_brand = 'Brand#12'
  AND cc.cc_state = 'CA'
  AND t_cr.t_hour BETWEEN 9 AND 17
  AND c.c_birth_country = 'USA'
  AND EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
          AND cr2.cr_return_amount > 1000
    )
GROUP BY cc.cc_name, i.i_category, w.w_warehouse_name, inv_agg.total_qty_on_hand
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_store_sales DESC
LIMIT 100
