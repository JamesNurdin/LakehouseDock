WITH joined_data AS (
    SELECT
        dd.d_year,
        i.i_category,
        r.r_reason_desc,
        CASE WHEN sr.sr_fee > 50 THEN 'High' ELSE 'Low' END AS fee_category,
        c.c_customer_id,
        COALESCE(sr.sr_return_amt, 0) + COALESCE(cr.cr_return_amount, 0) + COALESCE(wr.wr_return_amt, 0) AS return_amount,
        COALESCE(sr.sr_fee, 0) + COALESCE(cr.cr_fee, 0) + COALESCE(wr.wr_fee, 0) AS total_fee
    FROM store_returns sr
    JOIN date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON dd.d_date_sk = cr.cr_returned_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON i.i_item_sk = p.p_item_sk
    JOIN web_returns wr ON dd.d_date_sk = wr.wr_returned_date_sk
    WHERE dd.d_year = 2001
      AND i.i_class_id IN (1, 5, 7)
      AND w.w_gmt_offset = -5.00
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc LIKE '%damaged%'
),
aggregated AS (
    SELECT
        d_year,
        i_category,
        r_reason_desc,
        fee_category,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        SUM(return_amount) AS total_return_amount,
        AVG(total_fee) AS avg_total_fee
    FROM joined_data
    GROUP BY ROLLUP (d_year, i_category, r_reason_desc, fee_category)
)
SELECT
    d_year,
    i_category,
    r_reason_desc,
    fee_category,
    distinct_customers,
    total_return_amount,
    avg_total_fee,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS return_rank
FROM aggregated
ORDER BY d_year ASC NULLS LAST,
         i_category ASC NULLS LAST,
         r_reason_desc ASC NULLS LAST,
         fee_category,
         total_return_amount DESC
LIMIT 100
