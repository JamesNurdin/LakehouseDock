WITH item_s AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)   -- sample roughly 10 % of rows
    WHERE i_rec_start_date >= DATE '1997-01-01'
      AND i_rec_start_date < DATE '2002-01-01'
)
SELECT
    i1.i_item_id,
    i1.i_product_name,
    cd1.cd_gender,
    r1.r_reason_desc,
    COUNT(DISTINCT sr.sr_ticket_number)                     AS store_return_cnt,
    SUM(sr.sr_return_amt_inc_tax)                          AS total_store_return_inc_tax,
    SUM(wr.wr_return_amt_inc_tax)                          AS total_web_return_inc_tax,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i1.i_item_sk
    )                                                       AS item_total_store_return_amt,
    (
        SELECT AVG(sr_all.sr_return_amt)
        FROM store_returns sr_all
    )                                                       AS avg_return_amt_overall
FROM web_returns wr
JOIN item_s i2 ON wr.wr_item_sk = i2.i_item_sk                              -- 1
JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk                            -- 2
JOIN customer_demographics cd2 ON wr.wr_refunded_cdemo_sk = cd2.cd_demo_sk    -- 3
JOIN customer_demographics cd3 ON wr.wr_returning_cdemo_sk = cd3.cd_demo_sk   -- 4
LEFT JOIN store_returns sr ON sr.sr_item_sk = i2.i_item_sk                     -- 5
FULL OUTER JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk                -- 6 (full outer)
JOIN item_s i1 ON sr.sr_item_sk = i1.i_item_sk                                 -- 7
JOIN customer_demographics cd1 ON sr.sr_cdemo_sk = cd1.cd_demo_sk             -- 8
JOIN reason r3 ON sr.sr_reason_sk = r3.r_reason_sk                             -- 9
WHERE EXISTS (
    SELECT 1
    FROM reason r_check
    WHERE r_check.r_reason_id = 'R001'
      AND r_check.r_reason_sk = r2.r_reason_sk
)
GROUP BY
    i1.i_item_id,
    i1.i_product_name,
    cd1.cd_gender,
    r1.r_reason_desc,
    i1.i_item_sk
HAVING SUM(sr.sr_return_amt) > (
    SELECT AVG(sr_all.sr_return_amt)
    FROM store_returns sr_all
)
ORDER BY total_store_return_inc_tax DESC
LIMIT 100
