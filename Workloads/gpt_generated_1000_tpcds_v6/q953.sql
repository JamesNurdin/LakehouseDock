WITH cust_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_email_address,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(cr.cr_return_amount) AS total_catalog_return,
        COUNT(*) AS cnt_catalog_returns
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND cr.cr_return_amount > 150
      AND cr.cr_return_quantity >= 1
      AND cr.cr_fee < 50
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_email_address, cd.cd_gender, hd.hd_income_band_sk
)
SELECT
    c.c_customer_id,
    c.c_email_address,
    cd.cd_gender,
    hd.hd_income_band_sk,
    COALESCE(sr.sr_total, 0) AS store_return_total,
    COALESCE(ws.ws_total, 0) AS web_sales_total,
    CASE
        WHEN COALESCE(ws.ws_total, 0) - COALESCE(sr.sr_total, 0) > 0 THEN 'Net Gain'
        ELSE 'Net Loss'
    END AS net_status,
    ws.order_cnt AS web_orders,
    ws.total_net_profit,
    ws.min_net_profit,
    ws.max_net_profit,
    cr.total_catalog_return,
    cr.cnt_catalog_returns
FROM cust_returns cr
JOIN customer c
    ON cr.c_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS sr_total
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND sr.sr_store_sk IN (284, 871)
      AND sr.sr_return_quantity > 0
    GROUP BY sr.sr_customer_sk
) sr
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS ws_total,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_net_profit) AS total_net_profit,
        MIN(ws.ws_net_profit) AS min_net_profit,
        MAX(ws.ws_net_profit) AS max_net_profit
    FROM web_sales ws
    JOIN time_dim t2
        ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'content'
      AND ws.ws_quantity BETWEEN 1 AND 5
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_bill_customer_sk = ws.ws_bill_customer_sk
            AND ws2.ws_ext_sales_price > 5000
      )
    GROUP BY ws.ws_bill_customer_sk
) ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE c.c_email_address LIKE '%@%.com'
  AND c.c_birth_year BETWEEN 1960 AND 1980
  AND cd.cd_credit_rating = 'Excellent'
  AND hd.hd_buy_potential = '50000-99999'
ORDER BY ws.total_net_profit DESC
LIMIT 100
