WITH inv_daily AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_date_sk
),
agg AS (
    SELECT
        cc.cc_name,
        d.d_date,
        d.d_date_sk AS date_sk,
        r.r_reason_desc,
        sm.sm_type,
        SUM(ss.ss_ext_sales_price)                      AS total_store_sales,
        SUM(cr.cr_return_amount)                        AS total_catalog_return,
        inv_daily.total_on_hand,
        COUNT(DISTINCT c.c_customer_sk)                AS unique_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inv_daily ON inv_daily.inv_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
                     AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'TX'
      AND c.c_preferred_cust_flag = 'Y'
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND r.r_reason_desc LIKE '%damage%'
      AND sm.sm_type = 'AIR'
      AND wp.wp_type = 'HOME'
      AND inv_daily.total_on_hand > 1000
    GROUP BY
        cc.cc_name,
        d.d_date,
        d.d_date_sk,
        r.r_reason_desc,
        sm.sm_type,
        inv_daily.total_on_hand
)
SELECT
    agg.cc_name,
    agg.d_date,
    agg.r_reason_desc,
    agg.sm_type,
    agg.total_store_sales,
    agg.total_catalog_return,
    agg.total_on_hand,
    agg.unique_customers,
    (
        SELECT MAX(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_sold_date_sk = agg.date_sk
    ) AS max_daily_sales_price,
    ROW_NUMBER() OVER (PARTITION BY agg.cc_name ORDER BY agg.total_store_sales DESC) AS sales_rank
FROM agg
ORDER BY agg.total_store_sales DESC
LIMIT 100
