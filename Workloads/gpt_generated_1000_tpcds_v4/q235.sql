WITH agg_returns AS (
    SELECT
        d.d_year AS year,
        r_store.r_reason_desc AS reason_desc,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(sr.sr_return_amt) + SUM(cr.cr_return_amount) AS total_return_amount
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd_store
      ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
    JOIN customer_address ca_store
      ON sr.sr_addr_sk = ca_store.ca_address_sk
    JOIN reason r_store
      ON sr.sr_reason_sk = r_store.r_reason_sk
    JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t2
      ON cr.cr_returned_time_sk = t2.t_time_sk
    JOIN customer c_refunded
      ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
      ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN household_demographics hd_refunded
      ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
      ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN customer_address ca_refunded
      ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
      ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r_cat
      ON cr.cr_reason_sk = r_cat.r_reason_sk
    JOIN income_band ib_store
      ON hd_store.hd_income_band_sk = ib_store.ib_income_band_sk
    JOIN income_band ib_refunded
      ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
    JOIN income_band ib_returning
      ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
    WHERE d.d_year = 2001
      AND ca_store.ca_county = 'Maricopa County'
      AND sr.sr_return_amt > 100
    GROUP BY d.d_year, r_store.r_reason_desc
)
SELECT
    year,
    reason_desc,
    distinct_customers,
    store_net_loss,
    catalog_net_loss,
    total_return_amount,
    CASE
        WHEN (store_net_loss + catalog_net_loss) > 20000 THEN 'Very High'
        WHEN (store_net_loss + catalog_net_loss) > 10000 THEN 'High'
        ELSE 'Medium'
    END AS overall_loss_category
FROM agg_returns
WHERE total_return_amount > 500
ORDER BY overall_loss_category DESC, total_return_amount DESC
LIMIT 100
