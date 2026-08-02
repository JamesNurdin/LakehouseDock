/* Goal: Combine store and web return data for 2001, summarize returns per item/date, and enrich each row with the total catalog return amount for the same item and date. */
WITH combined_returns AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_product_name AS item_name,
        d.d_date AS return_date,
        'store' AS source,
        SUM(sr.sr_return_quantity) AS total_quantity,
        SUM(sr.sr_return_amt_inc_tax) AS total_amount_inc_tax
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_current_price > 100
      AND hd.hd_vehicle_count >= 1
      AND d.d_year = 2001
    GROUP BY i.i_item_sk, i.i_product_name, d.d_date
    UNION ALL
    SELECT
        i.i_item_sk AS item_sk,
        i.i_product_name AS item_name,
        d.d_date AS return_date,
        'web' AS source,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_amount_inc_tax
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE i.i_category = 'Electronics'
      AND d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_item_sk, i.i_product_name, d.d_date
)
SELECT
    cr.item_sk,
    cr.item_name,
    cr.return_date,
    cr.source,
    cr.total_quantity,
    cr.total_amount_inc_tax,
    (
        SELECT COALESCE(SUM(cr2.cr_return_amt_inc_tax), 0)
        FROM catalog_returns cr2
        JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        WHERE cr2.cr_item_sk = cr.item_sk
          AND d2.d_date = cr.return_date
    ) AS catalog_return_total_inc_tax
FROM combined_returns cr
WHERE cr.total_quantity > 0
ORDER BY cr.total_amount_inc_tax DESC
LIMIT 100
