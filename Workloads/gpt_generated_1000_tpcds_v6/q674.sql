WITH filtered_web AS (
    SELECT
        wr.wr_returned_date_sk AS returned_date_sk,
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_web_page_sk,
        wr.wr_refunded_cdemo_sk,
        wp.wp_url,
        wp.wp_type,
        d.d_year,
        d.d_month_seq,
        ca.ca_city,
        ca.ca_zip
    FROM web_returns wr
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(wp.wp_url, '^https?://[^/]*\\.com/.*sale')
      AND ca.ca_zip LIKE '9___'
)
SELECT
    fw.d_year,
    fw.d_month_seq,
    fw.wp_type,
    SUM(fw.wr_return_amt) AS total_return_amt,
    SUM(fw.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT fw.wr_order_number) AS distinct_orders,
    CASE WHEN SUM(fw.wr_return_amt) > 10000 THEN 'High' ELSE 'Low' END AS return_level,
    CONCAT(fw.ca_city, '-', SUBSTRING(fw.ca_zip, 1, 5)) AS city_zip,
    ROW_NUMBER() OVER (PARTITION BY fw.d_year ORDER BY SUM(fw.wr_return_amt) DESC) AS rank_in_year
FROM filtered_web fw
JOIN customer_demographics cd
  ON fw.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE EXISTS (
        SELECT 1
        FROM catalog_sales cs
        WHERE cs.cs_order_number = fw.wr_order_number
          AND cs.cs_quantity > 5
    )
GROUP BY fw.d_year, fw.d_month_seq, fw.wp_type, fw.ca_city, fw.ca_zip
ORDER BY fw.d_year DESC, total_return_amt DESC
LIMIT 100
