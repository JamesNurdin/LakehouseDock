WITH sales_agg AS (
    SELECT
        ws_ws.ws_item_sk,
        ws_ws.ws_sold_date_sk,
        ws_ws.ws_sold_time_sk,
        ws_ws.ws_ship_mode_sk,
        ws_ws.ws_promo_sk,
        ws_ws.ws_web_page_sk,
        ws_ws.ws_web_site_sk,
        ws_ws.ws_bill_hdemo_sk,
        ws_ws.ws_ship_hdemo_sk,
        ws_ws.ws_order_number,
        SUM(ws_ws.ws_ext_sales_price) AS total_sales,
        SUM(ws_ws.ws_quantity) AS total_qty
    FROM web_sales ws_ws
    WHERE ws_ws.ws_quantity > 0
      AND ws_ws.ws_ext_sales_price > 0
      AND ws_ws.ws_ship_mode_sk IS NOT NULL
    GROUP BY
        ws_ws.ws_item_sk,
        ws_ws.ws_sold_date_sk,
        ws_ws.ws_sold_time_sk,
        ws_ws.ws_ship_mode_sk,
        ws_ws.ws_promo_sk,
        ws_ws.ws_web_page_sk,
        ws_ws.ws_web_site_sk,
        ws_ws.ws_bill_hdemo_sk,
        ws_ws.ws_ship_hdemo_sk,
        ws_ws.ws_order_number
)
SELECT
    i.i_brand,
    sm.sm_type,
    t.t_shift,
    SUM(sa.total_sales) AS sum_sales,
    COUNT(DISTINCT sa.ws_item_sk) AS distinct_items
FROM sales_agg sa
FULL OUTER JOIN web_returns wr
    ON sa.ws_order_number = wr.wr_order_number
LEFT JOIN item i
    ON i.i_item_sk = COALESCE(sa.ws_item_sk, wr.wr_item_sk)
LEFT JOIN time_dim t
    ON t.t_time_sk = COALESCE(sa.ws_sold_time_sk, wr.wr_returned_time_sk)
LEFT JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = sa.ws_ship_mode_sk
LEFT JOIN promotion p
    ON p.p_promo_sk = sa.ws_promo_sk
LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = COALESCE(sa.ws_web_page_sk, wr.wr_web_page_sk)
LEFT JOIN web_site ws
    ON ws.web_site_sk = sa.ws_web_site_sk
LEFT JOIN household_demographics hd_bill
    ON hd_bill.hd_demo_sk = sa.ws_bill_hdemo_sk
LEFT JOIN household_demographics hd_ship
    ON hd_ship.hd_demo_sk = sa.ws_ship_hdemo_sk
LEFT JOIN income_band ib
    ON ib.ib_income_band_sk = hd_bill.hd_income_band_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
WHERE i.i_item_sk IN (
        SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 0
        INTERSECT
        SELECT p_item_sk FROM promotion WHERE p_discount_active = 'Y'
    )
  AND i.i_color IN ('turquoise', 'royal')
  AND sm.sm_carrier = 'FEDEX'
  AND t.t_shift = 'first'
  AND ib.ib_upper_bound > 50000
GROUP BY GROUPING SETS (
    (i.i_brand, sm.sm_type, t.t_shift),
    (i.i_brand, sm.sm_type),
    (i.i_brand),
    ()
)
ORDER BY sum_sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
