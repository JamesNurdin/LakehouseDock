WITH sales_agg AS (
        SELECT
            ss_sold_date_sk,
            COUNT(DISTINCT ss_ticket_number) AS tickets_sold,
            SUM(ss_net_paid)               AS total_net_paid,
            SUM(ss_net_profit)             AS total_profit,
            SUM(ss_quantity)               AS total_quantity
        FROM store_sales
        GROUP BY ss_sold_date_sk
    ),
    returns_agg AS (
        SELECT
            sr_returned_date_sk,
            SUM(sr_return_amt)        AS total_return_amt,
            AVG(sr_store_credit)      AS avg_store_credit,
            MAX(sr_return_quantity)   AS max_return_qty
        FROM store_returns
        GROUP BY sr_returned_date_sk
    ),
    web_returns_agg AS (
        SELECT
            wr_returned_date_sk,
            SUM(wr_return_amt) AS total_web_return_amt
        FROM web_returns
        GROUP BY wr_returned_date_sk
    )
SELECT
    d.d_year,
    d.d_month_seq,
    cp.cp_catalog_page_number,
    s.tickets_sold,
    s.total_net_paid,
    r.total_return_amt,
    r.avg_store_credit,
    r.max_return_qty,
    w.total_web_return_amt,
    s.total_profit - COALESCE(r.total_return_amt, 0) - COALESCE(w.total_web_return_amt, 0) AS net_profit_after_all_returns
FROM date_dim d
JOIN sales_agg s
    ON s.ss_sold_date_sk = d.d_date_sk
LEFT JOIN returns_agg r
    ON r.sr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns_agg w
    ON w.wr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND d.d_quarter_seq = 14
    AND cp.cp_catalog_page_number IN (12, 16)
    AND s.total_quantity > 1000
    AND r.avg_store_credit > 20.00
ORDER BY
    d.d_year,
    d.d_month_seq,
    s.total_net_paid DESC
