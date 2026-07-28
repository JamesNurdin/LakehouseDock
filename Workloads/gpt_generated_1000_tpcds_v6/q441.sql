WITH catalog_agg AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_hdemo_sk,
        SUM(cr.cr_return_amount)        AS total_catalog_return,
        SUM(cr.cr_net_loss)            AS total_catalog_loss,
        COUNT(*)                       AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cr.cr_returned_date_sk, cr.cr_ship_mode_sk, cr.cr_refunded_hdemo_sk
)
SELECT
    d_ret.d_year                                   AS return_year,
    sm.sm_code                                     AS ship_mode_code,
    ib.ib_income_band_sk                           AS income_band_sk,
    ca_ref.ca_state                                AS customer_state,
    c_ref.c_preferred_cust_flag                    AS preferred_customer,
    ws.web_name                                    AS web_site_name,
    cat.total_catalog_return                       AS catalog_return_amount,
    cat.total_catalog_loss                         AS catalog_loss_amount,
    CASE WHEN cat.total_catalog_loss > 5000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
    COALESCE(wr_sum.wr_return_amt, 0)               AS web_return_amount
FROM catalog_agg cat
JOIN date_dim d_ret
    ON cat.cr_returned_date_sk = d_ret.d_date_sk                     -- join rule 1
JOIN ship_mode sm
    ON cat.cr_ship_mode_sk = sm.sm_ship_mode_sk                       -- join rule 2
JOIN household_demographics hd_ref
    ON cat.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk                  -- join rule 3
JOIN income_band ib
    ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk               -- join rule 4
LEFT JOIN customer c_ref
    ON c_ref.c_current_hdemo_sk = hd_ref.hd_demo_sk                  -- join rule 5 (customer to hd)
LEFT JOIN customer_address ca_ref
    ON c_ref.c_current_addr_sk = ca_ref.ca_address_sk                -- join rule 6 (customer to address)
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk                         -- join rule 7 (web_site to date_dim)
LEFT JOIN (
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS wr_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
) wr_sum
    ON wr_sum.wr_returned_date_sk = d_ret.d_date_sk                  -- join rule 8 (web_returns to date_dim)
WHERE d_ret.d_year = 2002
GROUP BY
    d_ret.d_year,
    sm.sm_code,
    ib.ib_income_band_sk,
    ca_ref.ca_state,
    c_ref.c_preferred_cust_flag,
    ws.web_name,
    cat.total_catalog_return,
    cat.total_catalog_loss,
    wr_sum.wr_return_amt
ORDER BY
    cat.total_catalog_loss DESC
LIMIT 100
