WITH catalog_unified AS (
    SELECT
        cr.cr_returned_time_sk AS time_sk,
        td.t_hour AS hour,
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_refunded_hdemo_sk AS hd_demo_sk,
        cr.cr_refunded_addr_sk AS addr_sk,
        'catalog' AS return_source
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE td.t_hour BETWEEN 9 AND 17                                   -- business hours
      AND c.c_salutation = 'Mr.'                                      -- salutation filter
      AND ca.ca_zip LIKE '9%'                                         -- zip‑code filter
      AND hd.hd_vehicle_count >= 1                                    -- at least one vehicle
      AND hd.hd_income_band_sk IN (10, 17, 20)                         -- income band filter
),
store_unified AS (
    SELECT
        sr.sr_return_time_sk AS time_sk,
        td.t_hour AS hour,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_hdemo_sk AS hd_demo_sk,
        sr.sr_addr_sk AS addr_sk,
        'store' AS return_source
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND c.c_salutation = 'Mr.'
      AND ca.ca_zip LIKE '9%'
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_income_band_sk IN (10, 17, 20)
),
web_unified AS (
    SELECT
        wr.wr_returned_time_sk AS time_sk,
        td.t_hour AS hour,
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss,
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_refunded_hdemo_sk AS hd_demo_sk,
        wr.wr_refunded_addr_sk AS addr_sk,
        'web' AS return_source
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND c.c_salutation = 'Mr.'
      AND ca.ca_zip LIKE '9%'
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_income_band_sk IN (10, 17, 20)
      AND wp.wp_type = 'content'                     -- only content pages
      AND wr.wr_reversed_charge > 100                -- sizable reversed charge
),
all_returns AS (
    SELECT * FROM catalog_unified
    UNION ALL
    SELECT * FROM store_unified
    UNION ALL
    SELECT * FROM web_unified
),
aggregated AS (
    SELECT
        ur.hour,
        c.c_salutation,
        ur.return_source,
        SUM(ur.return_amount) AS total_return_amount,
        SUM(ur.net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM all_returns ur
    JOIN customer c ON ur.customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY GROUPING SETS (
        (ur.hour, c.c_salutation, ur.return_source),
        (ur.hour, ur.return_source),
        (c.c_salutation, ur.return_source),
        (ur.return_source)
    )
)
SELECT
    hour,
    c_salutation,
    return_source,
    total_return_amount,
    total_net_loss,
    cnt_returns,
    RANK() OVER (PARTITION BY return_source ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
