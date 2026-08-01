WITH returns_a AS (
    SELECT d_ret.d_date AS return_date,
           cd.cd_gender AS gender,
           sr.sr_return_amt AS return_amount,
           sr.sr_return_quantity AS return_qty,
           CASE WHEN ib.ib_upper_bound > 100000 THEN 'High Income' ELSE 'Low Income' END AS income_category,
           p.p_purpose,
           r.r_reason_desc,
           promo_stats.promo_count
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d_ret.d_date_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS promo_count
        FROM promotion p2
        WHERE p2.p_start_date_sk = d_ret.d_date_sk
    ) AS promo_stats
    WHERE ca.ca_country = 'United States'
      AND ca.ca_city = 'Glendale'
      AND wp.wp_image_count >= 5
      AND wp.wp_rec_end_date = DATE '2000-09-02'
      AND p.p_channel_press = 'N'
      AND p.p_purpose = 'Unknown'
      AND sr.sr_customer_sk IN (SELECT sr_customer_sk FROM store_returns WHERE sr_return_amt > 0)
      AND r.r_reason_desc = 'Damaged Item'
),
returns_b AS (
    SELECT d_ret.d_date AS return_date,
           cd.cd_gender AS gender,
           sr.sr_return_amt AS return_amount,
           sr.sr_return_quantity AS return_qty,
           CASE WHEN ib.ib_upper_bound > 100000 THEN 'High Income' ELSE 'Low Income' END AS income_category,
           p.p_purpose,
           r.r_reason_desc,
           promo_stats.promo_count
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d_ret.d_date_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS promo_count
        FROM promotion p2
        WHERE p2.p_start_date_sk = d_ret.d_date_sk
    ) AS promo_stats
    WHERE ca.ca_country = 'United States'
      AND ca.ca_city = 'Oak Ridge'
      AND wp.wp_image_count >= 5
      AND wp.wp_rec_end_date = DATE '1999-09-03'
      AND p.p_channel_press = 'N'
      AND p.p_purpose = 'Unknown'
      AND sr.sr_customer_sk IN (SELECT sr_customer_sk FROM store_returns WHERE sr_return_amt > 0)
      AND r.r_reason_desc = 'Customer Not Satisfied'
),
unioned_returns AS (
    SELECT return_date,
           gender,
           return_amount,
           return_qty,
           income_category,
           p_purpose,
           r_reason_desc,
           promo_count
    FROM returns_a
    UNION
    SELECT return_date,
           gender,
           return_amount,
           return_qty,
           income_category,
           p_purpose,
           r_reason_desc,
           promo_count
    FROM returns_b
)
SELECT
    return_date,
    gender,
    income_category,
    SUM(return_amount) AS total_return_amount,
    AVG(return_qty) AS avg_return_qty,
    COUNT(*) AS transaction_count,
    MIN(return_amount) AS min_return_amount,
    MAX(return_amount) AS max_return_amount,
    SUM(promo_count) AS total_promo_count
FROM unioned_returns
GROUP BY GROUPING SETS (
    (return_date, gender, income_category),
    (return_date, gender),
    (return_date),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
