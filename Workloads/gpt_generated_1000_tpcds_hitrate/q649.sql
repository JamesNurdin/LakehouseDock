WITH
cat_ret AS (
    SELECT
        d.d_year,
        i.i_brand,
        s.s_state,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cc.cc_company_name,
        cp.cp_type,
        sm.sm_type AS ship_type,
        r.r_reason_desc,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        ca.ca_city
    FROM date_dim d
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'TX'
      AND ib.ib_upper_bound <= 150000
      AND cc.cc_company_name = 'anti'
),
web_ret AS (
    SELECT
        d.d_year,
        i.i_brand,
        s.s_state,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        cc.cc_company_name,
        cp.cp_type,
        r.r_reason_desc,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        ca.ca_city
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'TX'
      AND ib.ib_upper_bound <= 150000
      AND cc.cc_company_name = 'anti'
),
all_returns AS (
    SELECT d_year, i_brand, s_state, return_amount FROM cat_ret
    UNION DISTINCT
    SELECT d_year, i_brand, s_state, return_amount FROM web_ret
)
SELECT
    d_year,
    i_brand,
    s_state,
    SUM(return_amount) AS total_return,
    AVG(return_amount) AS avg_return,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(return_amount) DESC) AS rn,
    CASE WHEN SUM(return_amount) > (SELECT AVG(return_amount) FROM all_returns) THEN 'Above Avg' ELSE 'Below Avg' END AS performance_flag
FROM all_returns
GROUP BY CUBE (d_year, i_brand, s_state)
HAVING SUM(return_amount) IS NOT NULL
ORDER BY total_return DESC
LIMIT 100
