WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        i.i_category_id,
        i.i_units,
        wp.wp_url,
        ca_ref.ca_county AS refunded_county,
        ca_ref.ca_state AS refunded_state,
        ca_ref.ca_street_type AS refunded_street_type,
        ca_ret.ca_city AS returning_city,
        ca_ret.ca_state AS returning_state
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '(?i)\b(Box|Pack)\b')
      AND wp.wp_url LIKE '%/products/%'
      AND substring(ca_ref.ca_street_type, 1, 1) = 'R'
)
SELECT
    i_category,
    CONCAT(refunded_county, ', ', refunded_state) AS refunded_location,
    COUNT(DISTINCT i_item_id) AS distinct_item_cnt,
    SUM(DISTINCT wr_return_amt) AS distinct_return_amt_sum,
    SUM(wr_return_amt) AS total_return_amt,
    CASE
        WHEN SUM(wr_return_amt) > 10000 THEN 'High'
        ELSE 'Medium'
    END AS return_level
FROM filtered_returns
GROUP BY
    i_category,
    CONCAT(refunded_county, ', ', refunded_state)
HAVING
    COUNT(DISTINCT i_item_id) > 5
    AND SUM(wr_return_amt) > 5000
ORDER BY total_return_amt DESC
LIMIT 100
