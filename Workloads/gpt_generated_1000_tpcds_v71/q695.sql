WITH cust_demo_income AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer c
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50000
),
union_data AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        cdi.c_customer_sk,
        cdi.c_first_name,
        cdi.c_last_name,
        ib.ib_lower_bound,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    JOIN cust_demo_income cdi
        ON cr.cr_refunded_customer_sk = cdi.c_customer_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w1
        ON cr.cr_warehouse_sk = w1.w_warehouse_sk
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    WHERE r.r_reason_desc = 'Damaged'
    GROUP BY cr.cr_returned_date_sk,
             cdi.c_customer_sk,
             cdi.c_first_name,
             cdi.c_last_name,
             ib.ib_lower_bound
    HAVING SUM(cr.cr_return_amount) > 1000

    UNION ALL

    SELECT
        wr.wr_returned_date_sk AS return_date_sk,
        cdi.c_customer_sk,
        cdi.c_first_name,
        cdi.c_last_name,
        ib.ib_lower_bound,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN cust_demo_income cdi
        ON wr.wr_refunded_customer_sk = cdi.c_customer_sk
    JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN warehouse w2
        ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    LEFT JOIN inventory inv
        ON w2.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    WHERE r.r_reason_desc = 'Customer not satisfied'
    GROUP BY wr.wr_returned_date_sk,
             cdi.c_customer_sk,
             cdi.c_first_name,
             cdi.c_last_name,
             ib.ib_lower_bound
    HAVING SUM(wr.wr_return_amt) > 500
)
SELECT
    ud.return_date_sk,
    ud.c_customer_sk,
    ud.c_first_name,
    ud.c_last_name,
    ud.ib_lower_bound,
    ud.total_return_amount,
    ud.cnt_returns
FROM union_data ud
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_customer_sk = ud.c_customer_sk
)
ORDER BY ud.total_return_amount DESC
LIMIT 100
