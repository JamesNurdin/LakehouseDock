SELECT
    we.web_site_id,
    we.web_name,
    wp.wp_type,
    d_ws_sold.d_year AS sales_year,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_web_sales_price,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ss.ss_ext_sales_price) AS total_store_sales_price,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
FROM
    web_sales ws
    INNER JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    INNER JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    INNER JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    INNER JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    INNER JOIN date_dim d_site_open
        ON we.web_open_date_sk = d_site_open.d_date_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
        AND wp.wp_web_page_sk = wr.wr_web_page_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN date_dim d_wr_ret
        ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w_ws.w_warehouse_sk
        AND inv.inv_date_sk = d_ws_sold.d_date_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_ws_sold.d_date_sk
    LEFT JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN date_dim d_sr_ret
        ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_ws_sold.d_date_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w_cr
        ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    LEFT JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE
    d_ws_sold.d_date >= DATE '2022-01-01'
    AND d_ws_sold.d_date <= DATE '2022-12-31'
    AND EXISTS (
        SELECT 1
        FROM promotion p_sub
        WHERE p_sub.p_promo_sk = ws.ws_promo_sk
          AND p_sub.p_discount_active = 'Y'
    )
GROUP BY
    ROLLUP (we.web_site_id, we.web_name, wp.wp_type, d_ws_sold.d_year)
ORDER BY
    we.web_site_id,
    wp.wp_type,
    d_ws_sold.d_year
LIMIT 100
