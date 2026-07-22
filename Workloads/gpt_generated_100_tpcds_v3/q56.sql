WITH sales_data AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_ext_sales_price,
        ss.ss_sales_price,
        ss.ss_coupon_amt,
        ss.ss_quantity,
        ss.ss_net_profit,
        i.i_item_sk,
        i.i_brand,
        i.i_current_price,
        cd.cd_demo_sk,
        cd.cd_gender
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE
        d.d_year = 2001
        AND d.d_quarter_seq = 6
        AND i.i_brand = 'Brand#23'
        AND i.i_current_price >= 30.00
        AND ss.ss_coupon_amt > 100.00
        AND cd.cd_gender = 'F'
)
SELECT
    sd.d_year,
    sd.d_month_seq,
    sd.i_brand,
    sd.cd_gender,
    cp.cp_department,
    SUM(sd.ss_ext_sales_price) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    SUM(sd.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT sd.ss_ticket_number) AS distinct_transactions
FROM
    sales_data sd
    JOIN store_returns sr ON sr.sr_ticket_number = sd.ss_ticket_number
    JOIN web_returns wr ON wr.wr_returned_date_sk = sd.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = sd.d_date_sk
WHERE
    sr.sr_return_quantity > 0
    AND wr.wr_return_quantity > 0
    AND cp.cp_department = 'Electronics'
GROUP BY
    sd.d_year,
    sd.d_month_seq,
    sd.i_brand,
    sd.cd_gender,
    cp.cp_department
ORDER BY
    total_store_sales DESC,
    sd.d_year,
    sd.d_month_seq
LIMIT 100
