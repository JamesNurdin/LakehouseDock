WITH returns_agg AS (
    SELECT
        wr_order_number,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_return_amt > 100
      AND wr_return_quantity > 0
    GROUP BY wr_order_number
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    p.p_promo_id,
    p.p_promo_name,
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    w.w_warehouse_id,
    w.w_city,
    wp.wp_web_page_id,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ra.total_return_amt) AS total_return_amount,
    AVG(ws.ws_quantity) AS avg_quantity,
    MAX(ws.ws_ext_sales_price) AS max_sales_price
FROM web_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN returns_agg ra
    ON ws.ws_order_number = ra.wr_order_number
WHERE c.c_preferred_cust_flag = 'Y'
  AND cd.cd_marital_status = 'M'
  AND p.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'CA'
  AND wp.wp_autogen_flag = 'N'
  AND ws.ws_quantity > 2
  AND wp.wp_char_count > 2000
  AND ra.total_return_amt > 200
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_amt > 500
    )
GROUP BY c.c_customer_id,
         c.c_first_name,
         c.c_last_name,
         cd.cd_gender,
         p.p_promo_id,
         p.p_promo_name,
         sm.sm_ship_mode_id,
         sm.sm_carrier,
         w.w_warehouse_id,
         w.w_city,
         wp.wp_web_page_id
HAVING SUM(ws.ws_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
