WITH cr_agg AS (
    SELECT
        cr_item_sk,
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_warehouse_sk,
        cr_refunded_cdemo_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk,
        cr_returning_cdemo_sk,
        cr_returning_hdemo_sk,
        cr_returning_addr_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY
        cr_item_sk,
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_warehouse_sk,
        cr_refunded_cdemo_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk,
        cr_returning_cdemo_sk,
        cr_returning_hdemo_sk,
        cr_returning_addr_sk
)
SELECT
    d.d_date,
    t.t_hour,
    w.w_warehouse_name,
    s.s_store_name,
    wp.wp_web_page_id,
    cr_agg.cr_item_sk,
    cr_agg.total_return_amount,
    cr_agg.total_return_quantity,
    CASE
        WHEN cr_agg.total_return_amount > 500 THEN 'Large'
        ELSE 'Small'
    END AS return_size_category,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cr_agg.total_return_amount DESC) AS return_rank_year,
    SUM(cr_agg.total_return_amount) OVER (
        PARTITION BY w.w_warehouse_sk
        ORDER BY d.d_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7day_return_amount,
    cd_refunded.cd_gender AS refunded_gender,
    hd_refunded.hd_income_band_sk AS refunded_income_band,
    ca_returning.ca_zip AS returning_zip,
    wp.wp_max_ad_count
FROM cr_agg
JOIN date_dim d
    ON cr_agg.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON cr_agg.cr_returned_time_sk = t.t_time_sk
JOIN warehouse w
    ON cr_agg.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_refunded
    ON cr_agg.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON cr_agg.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_refunded
    ON cr_agg.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON cr_agg.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN customer_address ca_refunded
    ON cr_agg.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr_agg.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
JOIN web_page wp
    ON wp.wp_access_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND w.w_county = 'Marshall County'
    AND s.s_state = 'CA'
    AND cd_refunded.cd_gender = 'M'
    AND ca_returning.ca_zip LIKE '68%'
    AND wp.wp_max_ad_count > 0
    AND cr_agg.total_return_amount > 100
    AND wr.wr_return_quantity > 0
ORDER BY cr_agg.total_return_amount DESC
LIMIT 100
