SELECT
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales
FROM
    store_sales ss
JOIN
    date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN
    household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN
    (
        SELECT
            sr_returned_date_sk,
            sr_item_sk,
            sr_ticket_number,
            sr_return_quantity,
            sr_return_amt
        FROM
            store_returns
        WHERE
            sr_returned_date_sk = 2451983
    ) sr
    ON sr.sr_item_sk = ss.ss_item_sk
WHERE
    d.d_year = 1924
    AND hd.hd_income_band_sk = 10
GROUP BY
    d.d_year,
    d.d_month_seq
HAVING
    COUNT(DISTINCT ss.ss_ticket_number) > 15
