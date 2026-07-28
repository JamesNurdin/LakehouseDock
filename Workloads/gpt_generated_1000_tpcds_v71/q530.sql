WITH base AS (
    SELECT
        d.d_year,
        s.s_store_name,
        i.i_category,
        COALESCE(r.r_reason_desc, cr_r.r_reason_desc, 'No Reason') AS reason_desc,
        ss.ss_ext_sales_price AS sales_price,
        ss.ss_net_profit,
        sr.sr_return_amt,
        cr.cr_return_amount,
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        tm.t_hour
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim tm ON ss.ss_sold_time_sk = tm.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason cr_r ON cr.cr_reason_sk = cr_r.r_reason_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
      AND tm.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound >= 50000
)
SELECT
    d_year,
    s_store_name,
    i_category,
    reason_desc,
    SUM(sales_price) AS total_sales,
    SUM(sr_return_amt) AS total_store_return,
    SUM(cr_return_amount) AS total_catalog_return,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    MIN(ib_lower_bound) AS min_income,
    MAX(ib_upper_bound) AS max_income,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(sales_price) DESC) AS sales_rank
FROM base
GROUP BY d_year, s_store_name, i_category, reason_desc
HAVING SUM(sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
