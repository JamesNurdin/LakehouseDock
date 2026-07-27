WITH cs AS (
    SELECT
        cs.*, 
        c1.c_customer_id AS bill_cust_id,
        c2.c_customer_id AS ship_cust_id,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        promo_cs.p_promo_name AS promo_name
    FROM catalog_sales cs
    JOIN customer c1
        ON cs.cs_bill_customer_sk = c1.c_customer_sk
    JOIN customer c2
        ON cs.cs_ship_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN promotion promo_cs
        ON cs.cs_promo_sk = promo_cs.p_promo_sk
)
SELECT
    cs.promo_name,
    r_cat.r_reason_desc,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    CASE WHEN SUM(COALESCE(cr.cr_return_quantity, 0)) > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_flag
FROM cs
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
LEFT JOIN reason r_cat
    ON cr.cr_reason_sk = r_cat.r_reason_sk
LEFT JOIN web_sales ws
    ON cs.cs_bill_customer_sk = ws.ws_bill_customer_sk
   AND cs.cs_ship_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN promotion promo_ws
    ON ws.ws_promo_sk = promo_ws.p_promo_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN reason r_web
    ON wr.wr_reason_sk = r_web.r_reason_sk
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
      AND wp.wp_type = 'product'
)
GROUP BY cs.promo_name, r_cat.r_reason_desc
ORDER BY total_sales DESC
LIMIT 100
