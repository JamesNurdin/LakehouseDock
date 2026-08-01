WITH all_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_returned_date_sk,
        cp.cp_department AS cp_department,
        cp.cp_type,
        w.w_warehouse_name,
        w.w_state,
        r.r_reason_desc,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_ext_discount_amt AS ws_ext_discount_amt,
        ws.ws_net_paid,
        p.p_promo_name,
        CASE
            WHEN cr.cr_return_amount > 1000 THEN 'Large'
            ELSE 'Small'
        END AS return_size
    FROM
        catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        cr.cr_return_amount > 0
        AND cp.cp_department = 'Books'
        AND w.w_state = 'CA'
        AND cd.cd_gender = 'M'
        AND ib.ib_upper_bound > 50000
)
SELECT
    return_size,
    cp_department,
    COUNT(*) AS cnt_returns,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(ws_ext_sales_price) AS avg_web_sales_price,
    SUM(ws_ext_discount_amt) AS total_web_discount
FROM
    all_data
GROUP BY
    return_size,
    cp_department
HAVING
    SUM(cr_return_amount) > 5000
ORDER BY
    total_return_amount DESC
