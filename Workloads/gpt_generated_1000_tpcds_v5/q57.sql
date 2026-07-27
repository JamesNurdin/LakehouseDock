WITH enriched AS (
    SELECT DISTINCT
        sr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        t.t_hour,
        t.t_am_pm,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wp.wp_type,
        wp.wp_char_count
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_cre ON wp.wp_creation_date_sk = d_cre.d_date_sk
    JOIN date_dim d_acc ON wp.wp_access_date_sk = d_acc.d_date_sk
    WHERE d_ret.d_year BETWEEN 2000 AND 2002
      AND t.t_hour BETWEEN 8 AND 17
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_buy_potential IN ('5001-10000', '>10000')
      AND wp.wp_type = 'product'
      AND d_cre.d_year = 2001
      AND d_acc.d_year = 2001
)
SELECT
    CASE
        WHEN SUM(e.sr_return_amt) > 2000 THEN 'High'
        WHEN SUM(e.sr_return_amt) > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_category,
    e.return_year,
    e.return_month,
    SUM(e.sr_return_amt) AS total_return_amount,
    SUM(e.sr_net_loss) AS total_net_loss,
    RANK() OVER (PARTITION BY e.return_year ORDER BY SUM(e.sr_return_amt) DESC) AS rank_in_year
FROM enriched e
GROUP BY GROUPING SETS (
    (e.return_year, e.return_month),
    (e.return_year),
    ()
)
ORDER BY e.return_year DESC,
         e.return_month NULLS LAST,
         total_return_amount DESC
LIMIT 100
