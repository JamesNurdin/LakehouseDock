/*
  Goal: Compare store and web return performance for items in the 'Sports' category sold in 'Case' units, focusing on high store credits and a specific return reason. The query aggregates total return amounts, average return quantities, and other key metrics per item brand and unit.
*/
WITH filtered AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_units,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_store_credit,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_reason_sk,
        wr.wr_returning_customer_sk
    FROM
        tpcds.item i
        LEFT JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
        LEFT JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
    WHERE
        i.i_category = 'Sports'                     -- filter 1
        AND i.i_units = 'Case'                       -- filter 2
        AND sr.sr_store_credit > 50                  -- filter 3 (realistic high store credit)
        AND wr.wr_reason_sk = 45                     -- filter 4 (specific return reason)
        AND wr.wr_returning_customer_sk IN (7875356, 10288429)  -- filter 5 (selected customers)
)
SELECT
    f.i_category,
    f.i_brand,
    f.i_units,
    COUNT(DISTINCT f.i_item_sk) AS distinct_item_count,
    SUM(COALESCE(f.sr_return_amt, 0)) AS total_store_return_amount,
    SUM(COALESCE(f.wr_return_amt, 0)) AS total_web_return_amount,
    SUM(COALESCE(f.sr_return_amt, 0) + COALESCE(f.wr_return_amt, 0)) AS total_combined_return_amount,
    AVG(f.sr_return_quantity) AS avg_store_return_quantity,
    MIN(f.wr_return_tax) AS min_web_return_tax,
    MAX(f.wr_return_tax) AS max_web_return_tax
FROM
    filtered f
GROUP BY
    f.i_category,
    f.i_brand,
    f.i_units
ORDER BY
    total_combined_return_amount DESC
LIMIT 100
