WITH catalog_cte AS (
    SELECT
        cs.cs_sold_date_sk                AS sold_date_sk,
        cs.cs_sold_time_sk                AS sold_time_sk,
        cs.cs_item_sk                     AS item_sk,
        cs.cs_order_number                AS order_number,
        cs.cs_quantity                    AS quantity,
        cs.cs_net_paid                    AS net_paid,
        cr.cr_return_quantity              AS return_quantity,
        cr.cr_return_amount                AS return_amount,
        cr.cr_reason_sk                    AS reason_sk,
        cs.cs_ship_mode_sk                 AS ship_mode_sk,
        cs.cs_bill_customer_sk             AS bill_customer_sk,
        cs.cs_ship_customer_sk             AS ship_customer_sk,
        cs.cs_bill_cdemo_sk                AS bill_cdemo_sk,
        cs.cs_ship_cdemo_sk                AS ship_cdemo_sk,
        cs.cs_bill_hdemo_sk                AS bill_hdemo_sk,
        cs.cs_ship_hdemo_sk                AS ship_hdemo_sk,
        cs.cs_bill_addr_sk                 AS bill_addr_sk,
        cs.cs_ship_addr_sk                 AS ship_addr_sk,
        t.t_hour                           AS hour,
        hd_bill.hd_income_band_sk          AS hd_income_band_sk
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    LEFT JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    LEFT JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_quantity > 0
),
web_cte AS (
    SELECT
        ws.ws_sold_date_sk                AS sold_date_sk,
        ws.ws_sold_time_sk                AS sold_time_sk,
        ws.ws_item_sk                     AS item_sk,
        ws.ws_order_number                AS order_number,
        ws.ws_quantity                    AS quantity,
        ws.ws_net_paid                    AS net_paid,
        wr.wr_return_quantity              AS return_quantity,
        wr.wr_return_amt                   AS return_amount,
        wr.wr_reason_sk                    AS reason_sk,
        ws.ws_ship_mode_sk                 AS ship_mode_sk,
        ws.ws_bill_customer_sk             AS bill_customer_sk,
        ws.ws_ship_customer_sk             AS ship_customer_sk,
        ws.ws_bill_cdemo_sk                AS bill_cdemo_sk,
        ws.ws_ship_cdemo_sk                AS ship_cdemo_sk,
        ws.ws_bill_hdemo_sk                AS bill_hdemo_sk,
        ws.ws_ship_hdemo_sk                AS ship_hdemo_sk,
        ws.ws_bill_addr_sk                 AS bill_addr_sk,
        ws.ws_ship_addr_sk                 AS ship_addr_sk,
        t.t_hour                           AS hour,
        hd_bill.hd_income_band_sk          AS hd_income_band_sk
    FROM web_sales ws
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    LEFT JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    LEFT JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_quantity > 0
),
combined AS (
    SELECT * FROM catalog_cte
    UNION DISTINCT
    SELECT * FROM web_cte
)
SELECT
    combined.sold_date_sk,
    combined.hour,
    SUM(COALESCE(combined.quantity, 0))               AS total_quantity,
    SUM(COALESCE(combined.net_paid, 0))               AS total_net_paid,
    SUM(COALESCE(combined.return_quantity, 0))       AS total_return_quantity,
    COUNT(DISTINCT combined.order_number)            AS distinct_orders,
    MIN(combined.return_amount)                      AS min_return_amount,
    MAX(combined.return_amount)                      AS max_return_amount,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM combined
LEFT JOIN income_band ib
    ON combined.hd_income_band_sk = ib.ib_income_band_sk
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_customer_sk = combined.bill_customer_sk
      AND ss.ss_quantity > 0
)
GROUP BY
    combined.sold_date_sk,
    combined.hour,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_net_paid DESC
LIMIT 100
