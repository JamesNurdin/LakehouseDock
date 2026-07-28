-- Goal: Compare high vs low credit categories across catalog and store returns for CA customers, aggregating return amounts.
WITH catalog_agg AS (
    SELECT
        CASE WHEN cr.cr_store_credit > 100 THEN 'High' ELSE 'Low' END AS credit_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(*) AS return_count,
        MIN(cr.cr_returned_date_sk) AS min_return_date_sk,
        MAX(cr.cr_returned_date_sk) AS max_return_date_sk
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amount > 500
      AND i.i_brand = 'barcallyable'
      AND ca.ca_state = 'CA'
    GROUP BY CASE WHEN cr.cr_store_credit > 100 THEN 'High' ELSE 'Low' END
),
store_agg AS (
    SELECT
        CASE WHEN sr.sr_store_credit > 100 THEN 'High' ELSE 'Low' END AS credit_category,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_return_amt) AS avg_return_amount,
        COUNT(*) AS return_count,
        MIN(sr.sr_returned_date_sk) AS min_return_date_sk,
        MAX(sr.sr_returned_date_sk) AS max_return_date_sk
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_amt > 300
      AND i.i_category = 'Electronics'
      AND ca.ca_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_customer_sk = c.c_customer_sk
            AND wp.wp_type = 'product'
      )
    GROUP BY CASE WHEN sr.sr_store_credit > 100 THEN 'High' ELSE 'Low' END
)
SELECT
    credit_category,
    SUM(total_return_amount) AS overall_total_return_amount,
    SUM(avg_return_amount * return_count) / SUM(return_count) AS overall_avg_return_amount,
    SUM(return_count) AS overall_return_count,
    MIN(min_return_date_sk) AS earliest_return_date_sk,
    MAX(max_return_date_sk) AS latest_return_date_sk
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
) combined
GROUP BY credit_category
ORDER BY overall_total_return_amount DESC
LIMIT 100
