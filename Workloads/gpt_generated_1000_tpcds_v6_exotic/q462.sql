WITH catalog_data AS (
    SELECT
        d_ret.d_year AS year,
        cp.cp_catalog_page_id AS entity_id,
        CAST('Catalog' AS varchar) AS entity_type,
        ca.ca_state AS state,
        CASE
            WHEN cr.cr_return_amount > 100 THEN 'High'
            WHEN cr.cr_return_amount > 0 THEN 'Low'
            ELSE 'None'
        END AS return_category,
        cr.cr_return_amount AS return_amount,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY cr.cr_return_amount DESC) AS rank_val,
        COUNT(*) OVER (PARTITION BY ca.ca_state) AS cnt_state
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN promotion p_start ON p_start.p_start_date_sk = d_ret.d_date_sk
    JOIN promotion p_end ON p_end.p_end_date_sk = d_ret.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d_ret.d_year = 2001
      AND s.s_market_id IN (1, 2, 3)
      AND ca.ca_state = 'TX'
      AND r.r_reason_id = 'AAAAAAAADBAAAAAA'
),
store_data AS (
    SELECT
        d_ret2.d_year AS year,
        s2.s_store_id AS entity_id,
        CAST('Store' AS varchar) AS entity_type,
        ca2.ca_state AS state,
        CASE
            WHEN sr.sr_return_amt_inc_tax > 500 THEN 'Big'
            ELSE 'Small'
        END AS return_category,
        sr.sr_return_amt_inc_tax AS return_amount,
        DENSE_RANK() OVER (PARTITION BY s2.s_store_id ORDER BY sr.sr_return_amt_inc_tax DESC) AS rank_val,
        COUNT(*) OVER (PARTITION BY s2.s_state) AS cnt_state
    FROM store_returns sr
    JOIN date_dim d_ret2 ON sr.sr_returned_date_sk = d_ret2.d_date_sk
    JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
    JOIN customer_address ca2 ON sr.sr_addr_sk = ca2.ca_address_sk
    JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
    JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
    JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    JOIN web_page wp2 ON wp2.wp_customer_sk = c2.c_customer_sk
    JOIN promotion p_start2 ON p_start2.p_start_date_sk = d_ret2.d_date_sk
    JOIN promotion p_end2 ON p_end2.p_end_date_sk = d_ret2.d_date_sk
    WHERE d_ret2.d_year = 2001
      AND s2.s_country = 'United States'
      AND ca2.ca_city = 'Austin'
      AND ib2.ib_upper_bound > 50000
)
SELECT *
FROM (
    SELECT year, entity_id, entity_type, state, return_category, return_amount, rank_val, cnt_state
    FROM catalog_data
    UNION ALL
    SELECT year, entity_id, entity_type, state, return_category, return_amount, rank_val, cnt_state
    FROM store_data
) AS combined
ORDER BY year DESC, return_category, rank_val
LIMIT 100
