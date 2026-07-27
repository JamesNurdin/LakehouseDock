WITH filtered_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 2000
)
SELECT source_type,
       year,
       SUM(net_loss) AS total_net_loss
FROM (
    SELECT 'catalog' AS source_type,
           d.d_year AS year,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN filtered_dates d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_county = 'Oldham County'
      AND cr.cr_return_quantity > 0
    UNION ALL
    SELECT 'web' AS source_type,
           d.d_year AS year,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN filtered_dates d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'product'
      AND EXISTS (
          SELECT 1
          FROM customer_address ca2
          WHERE ca2.ca_address_sk = wr.wr_refunded_addr_sk
            AND ca2.ca_city = 'Farmington'
      )
) AS combined
GROUP BY source_type, year
ORDER BY source_type, year DESC
LIMIT 100
