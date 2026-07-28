/*
Goal: Identify web page types that generated product‑related returns in the year 2001 for returning customers whose city name starts with "A". The query extracts the product identifier from the URL, builds readable labels, classifies total net loss against the overall average, and ranks the results.
*/
WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_web_page_sk,
        wr.wr_returning_addr_sk,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_reason_sk,
        wp.wp_type,
        wp.wp_url,
        ca.ca_city,
        d.d_year
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(wp.wp_url, '.*product.*')
      AND ca.ca_city LIKE 'A%'
      AND d.d_year = 2001
)
SELECT
    fr.wp_type,
    COUNT(*) AS return_cnt,
    SUM(fr.wr_net_loss) AS total_loss,
    CASE
        WHEN SUM(fr.wr_net_loss) > (SELECT avg(wr2.wr_net_loss) FROM web_returns wr2) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_category,
    regexp_extract(fr.wp_url, 'product/([0-9]+)', 1) AS product_id,
    concat('URL:', fr.wp_url) AS url_label,
    substring(fr.wp_url FROM 1 FOR 15) AS url_prefix
FROM filtered_returns fr
GROUP BY fr.wp_type, fr.wp_url
ORDER BY total_loss DESC
LIMIT 20
