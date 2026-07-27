WITH filtered_returns AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_web_page_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_returning_addr_sk,
        wr.wr_return_amt,
        wr.wr_fee,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_returned_time_sk
    FROM web_returns wr
    WHERE wr.wr_fee > 15.00                     -- filter 1
      AND wr.wr_net_loss BETWEEN 100 AND 500    -- filter 2
      AND wr.wr_return_quantity >= 1           -- filter 3
      AND wr.wr_returned_time_sk IN (29630, 67381, 61757)  -- filter 4
)
SELECT
    i.i_brand,
    i.i_brand_id,
    wp.wp_type,
    COALESCE(ca_refunded.ca_location_type, 'unknown') AS refunded_location_type,
    COUNT(*) AS returns_cnt,
    SUM(fr.wr_return_amt) AS total_return_amt,
    AVG(fr.wr_fee) AS avg_fee,
    MIN(fr.wr_net_loss) AS min_net_loss,
    MAX(fr.wr_net_loss) AS max_net_loss
FROM filtered_returns fr
JOIN item i
    ON fr.wr_item_sk = i.i_item_sk                     -- inner join
JOIN web_page wp
    ON fr.wr_web_page_sk = wp.wp_web_page_sk           -- inner join
LEFT JOIN customer_address ca_refunded
    ON fr.wr_refunded_addr_sk = ca_refunded.ca_address_sk   -- left outer join
JOIN customer_address ca_returning
    ON fr.wr_returning_addr_sk = ca_returning.ca_address_sk -- inner join
WHERE i.i_wholesale_cost < 2.00                     -- filter 5
  AND i.i_brand = 'importoscholar #2'               -- filter 6
  AND ca_returning.ca_street_type = 'Street'       -- filter 7
  AND wp.wp_type = 'product'                        -- filter 8
  AND wp.wp_char_count > 1000                      -- filter 9
GROUP BY
    i.i_brand,
    i.i_brand_id,
    wp.wp_type,
    COALESCE(ca_refunded.ca_location_type, 'unknown')
ORDER BY total_return_amt DESC
LIMIT 100
