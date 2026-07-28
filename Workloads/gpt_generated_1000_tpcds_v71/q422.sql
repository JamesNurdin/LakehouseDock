WITH returns_agg AS (
    SELECT
        wr_order_number,
        wr_item_sk,
        wr_reason_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_return_quantity > 1
      AND wr_return_amt > 20
    GROUP BY wr_order_number, wr_item_sk, wr_reason_sk
)
SELECT
    ws.ws_order_number,
    i.i_item_id,
    i.i_product_name,
    sm.sm_carrier,
    wsite.web_name AS site_name,
    r.r_reason_desc,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    COALESCE(SUM(ra.total_return_amt), 0) AS total_return_amount,
    COUNT(*) AS line_item_cnt
FROM web_sales ws
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN returns_agg ra
    ON ws.ws_order_number = ra.wr_order_number
   AND ws.ws_item_sk = ra.wr_item_sk
JOIN reason r
    ON ra.wr_reason_sk = r.r_reason_sk
WHERE i.i_category = 'Electronics'
  AND i.i_current_price BETWEEN 100 AND 500
  AND p.p_purpose = 'Clearance'
  AND sm.sm_code = 'AIR'
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        JOIN reason r2 ON wr2.wr_reason_sk = r2.r_reason_sk
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND r2.r_reason_desc = 'Package was damaged'
    )
GROUP BY
    ws.ws_order_number,
    i.i_item_id,
    i.i_product_name,
    sm.sm_carrier,
    wsite.web_name,
    r.r_reason_desc
ORDER BY total_sales DESC
LIMIT 100
