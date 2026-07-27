WITH
    filtered_sales AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_item_sk,
            ss.ss_customer_sk,
            ss.ss_cdemo_sk,
            ss.ss_hdemo_sk,
            ss.ss_ticket_number,
            ss.ss_net_paid,
            ss.ss_sales_price,
            ss.ss_net_profit
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450500
          AND c.c_birth_year = 1975
          AND cd.cd_gender = 'M'
          AND hd.hd_income_band_sk IN (7, 12, 14)
          AND ss.ss_net_profit > 0
    ),
    joined_data AS (
        SELECT
            c.c_customer_id,
            c.c_customer_sk,
            cd.cd_gender,
            hd.hd_income_band_sk,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            ss.ss_net_paid,
            ss.ss_sales_price,
            ss.ss_net_profit,
            ss.ss_ticket_number
        FROM filtered_sales ss
        JOIN catalog_returns cr
            ON cr.cr_refunded_customer_sk = ss.ss_customer_sk
           AND cr.cr_refunded_cdemo_sk = ss.ss_cdemo_sk
           AND cr.cr_refunded_hdemo_sk = ss.ss_hdemo_sk
        JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
        JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
        JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
        WHERE cr.cr_return_amount > 20.00
          AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450500
    ),
    agg AS (
        SELECT
            c_customer_id,
            c_customer_sk,
            cd_gender,
            hd_income_band_sk,
            SUM(cr_return_amount) AS total_return_amount,
            SUM(ss_net_paid) AS total_sales,
            COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
            AVG(ss_sales_price) AS avg_sales_price,
            MIN(cr_return_amount) AS min_return_amount,
            MAX(ss_net_profit) AS max_profit,
            (
                SELECT AVG(cr2.cr_return_amount)
                FROM catalog_returns cr2
                WHERE cr2.cr_refunded_customer_sk = c_customer_sk
            ) AS avg_customer_return_amount
        FROM joined_data
        GROUP BY c_customer_id, c_customer_sk, cd_gender, hd_income_band_sk
    )
SELECT
    c_customer_id,
    cd_gender,
    hd_income_band_sk,
    total_return_amount,
    total_sales,
    distinct_tickets,
    avg_sales_price,
    min_return_amount,
    max_profit,
    avg_customer_return_amount,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_rank,
    SUM(total_sales) OVER (
        PARTITION BY cd_gender
        ORDER BY total_return_amount
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_sales_by_gender
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
