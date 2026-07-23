/*
Goal: Compute total and average combined return amount (catalog returns) and sales price (web sales) by year, state, and gender for a specific demographic segment and shipping mode, then aggregate these metrics per year‑state.
*/
WITH raw AS (
    SELECT
        d.d_year,
        s.s_state,
        cd.cd_gender,
        cr.cr_return_amount,
        ws.ws_ext_sales_price,
        (cr.cr_return_amount + ws.ws_ext_sales_price) AS total_return_and_sales
    FROM tpcds.date_dim d
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq BETWEEN 1200 AND 1300
        AND s.s_state = 'CA'
        AND hd.hd_buy_potential = '1001-5000'
        AND ib.ib_upper_bound <= 50000
        AND sm.sm_type = 'REGULAR'
        AND r.r_reason_desc LIKE '%Damaged%'
        AND ws.ws_ext_sales_price > 0
        AND cr.cr_return_amount > 0
        AND EXISTS (
            SELECT 1 FROM tpcds.inventory i
            WHERE i.inv_date_sk = d.d_date_sk
              AND i.inv_quantity_on_hand > 0
        )
        AND s.s_closed_date_sk = d.d_date_sk
        AND cp.cp_start_date_sk = d.d_date_sk
        AND ws_site.web_open_date_sk = d.d_date_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_returning_customer_sk = c.c_customer_sk
        AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_reason_sk = r.r_reason_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_ship_date_sk = d.d_date_sk
),
grouped AS (
    SELECT
        d_year,
        s_state,
        cd_gender,
        SUM(total_return_and_sales) AS sum_total_return_and_sales,
        AVG(total_return_and_sales) AS avg_total_return_and_sales,
        COUNT(*) AS txn_count
    FROM raw
    GROUP BY d_year, s_state, cd_gender
)
SELECT
    d_year,
    s_state,
    SUM(sum_total_return_and_sales) AS total_sum_by_year_state,
    AVG(avg_total_return_and_sales) AS avg_of_avg_by_year_state,
    SUM(txn_count) AS total_txn_count
FROM grouped
WHERE sum_total_return_and_sales > 5000
GROUP BY d_year, s_state
ORDER BY total_sum_by_year_state DESC
LIMIT 100
