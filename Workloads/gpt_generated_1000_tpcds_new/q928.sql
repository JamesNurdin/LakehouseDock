WITH inv_wh AS (
        SELECT
            i.inv_date_sk,
            i.inv_item_sk,
            i.inv_warehouse_sk,
            i.inv_quantity_on_hand,
            w.w_warehouse_name,
            w.w_city
        FROM inventory i
        FULL OUTER JOIN warehouse w
            ON i.inv_warehouse_sk = w.w_warehouse_sk
    ),
    distinct_reasons AS (
        SELECT DISTINCT r_reason_sk, r_reason_desc
        FROM reason
    )
SELECT
    ws.ws_order_number,
    d_sold.d_year,
    i.i_item_id,
    i.i_brand,
    p.p_promo_name,
    sm.sm_type,
    cd_bill.cd_gender,
    site.web_country,
    cp.cp_department,
    iw.inv_quantity_on_hand,
    dr.r_reason_desc,
    ws.ws_net_profit,
    DENSE_RANK() OVER (PARTITION BY d_sold.d_year ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS max_promo_cost
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN distinct_reasons dr
    ON sr.sr_reason_sk = dr.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN inv_wh iw
    ON iw.inv_item_sk = i.i_item_sk
    AND iw.inv_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_brand = 'BrandX'
  AND p.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
  AND cd_bill.cd_gender = 'M'
  AND site.web_country = 'United States'
  AND ws.ws_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_color = 'RED')
ORDER BY ws.ws_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
