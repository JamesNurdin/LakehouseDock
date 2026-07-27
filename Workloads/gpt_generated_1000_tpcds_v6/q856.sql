WITH joined_data AS (
    SELECT
        ws.web_site_id,
        d_ret.d_year,
        hd_refunded.hd_income_band_sk,
        CASE WHEN hd_refunded.hd_income_band_sk <= 3 THEN 'Low' ELSE 'High' END AS income_category,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_return_quantity
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE d_ret.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND wp.wp_char_count > 2000
      AND wp.wp_image_count <= 5
      AND hd_refunded.hd_income_band_sk IN (2, 4, 5)
      AND hd_returning.hd_dep_count >= 2
      AND ws.web_country = 'United States'
      AND c_refunded.c_preferred_cust_flag = 'Y'
),
agg_data AS (
    SELECT
        web_site_id,
        d_year,
        hd_income_band_sk,
        income_category,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(wr_return_quantity) AS avg_return_qty
    FROM joined_data
    GROUP BY
        web_site_id,
        d_year,
        hd_income_band_sk,
        income_category
    HAVING SUM(wr_net_loss) > 1000
)
SELECT
    web_site_id,
    d_year,
    hd_income_band_sk,
    income_category,
    total_return_amount,
    total_net_loss,
    avg_return_qty,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg_data
ORDER BY d_year, net_loss_rank
LIMIT 100
