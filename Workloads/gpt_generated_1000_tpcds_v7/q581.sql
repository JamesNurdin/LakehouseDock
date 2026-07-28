WITH sales_returns AS (
    SELECT
        cd.cd_gender,
        ib.ib_upper_bound,
        ss.ss_net_paid,
        sr.sr_net_loss,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_ticket_number = sr.sr_ticket_number
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_sales.d_year = 2001
      AND ib.ib_upper_bound <= 50000
      AND wp.wp_type = 'article'
),
agg1 AS (
    SELECT
        cd_gender,
        ib_upper_bound,
        SUM(ss_net_paid) AS total_sales,
        SUM(sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT ss_ticket_number) AS num_transactions
    FROM sales_returns
    GROUP BY ROLLUP (cd_gender, ib_upper_bound)
)
SELECT
    cd_gender,
    ib_upper_bound,
    total_sales,
    total_return_loss,
    num_transactions,
    (total_sales - total_return_loss) AS net_profit
FROM agg1
WHERE total_sales > 100000
ORDER BY cd_gender, ib_upper_bound
