WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
),
joined_data AS (
    SELECT
        d.d_year,
        i.i_brand,
        sm.sm_type AS ship_mode_type,
        ws.ws_net_profit,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        ia.total_on_hand,
        ws.ws_quantity,
        ws.ws_ext_sales_price
    FROM date_dim d
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    FULL OUTER JOIN inventory_agg ia ON ia.inv_item_sk = i.i_item_sk AND ia.inv_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND we.web_city = 'Georgetown'
      AND ws.ws_quantity > 0
)
SELECT
    d_year,
    i_brand,
    ship_mode_type,
    SUM(ws_net_profit) AS total_profit,
    SUM(cr_return_amount) AS total_catalog_return,
    SUM(sr_return_amt) AS total_store_return,
    SUM(wr_return_amt) AS total_web_return,
    SUM(total_on_hand) AS total_inventory_on_hand,
    SUM(ws_quantity) AS total_quantity_sold,
    SUM(ws_ext_sales_price) AS total_sales
FROM joined_data
GROUP BY ROLLUP (d_year, i_brand, ship_mode_type)
ORDER BY d_year DESC NULLS LAST, i_brand, ship_mode_type
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
