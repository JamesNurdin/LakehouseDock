WITH catalog_data AS (
    SELECT
        i.i_category AS category,
        ca.ca_country AS country,
        regexp_extract(ca.ca_zip, '([0-9]{2})', 1) AS zip_prefix,
        cr.cr_net_loss AS net_loss,
        CASE WHEN cr.cr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_severity,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_product_name, '(?i)advanced')
      AND ca.ca_zip LIKE '9%'
),
web_data AS (
    SELECT
        i.i_category AS category,
        ca.ca_country AS country,
        regexp_extract(ca.ca_zip, '([0-9]{2})', 1) AS zip_prefix,
        wr.wr_net_loss AS net_loss,
        CASE WHEN wr.wr_net_loss > 100 THEN 'High' ELSE 'Low' END AS loss_severity,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_product_name, '(?i)advanced')
      AND ca.ca_zip LIKE '9%'
)
SELECT
    category,
    country,
    zip_prefix,
    sum(net_loss) AS total_net_loss,
    count(*) AS total_returns,
    sum(CASE WHEN loss_severity = 'High' THEN 1 ELSE 0 END) AS high_loss_returns
FROM (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM web_data
) AS all_returns
GROUP BY category, country, zip_prefix
ORDER BY total_net_loss DESC
LIMIT 100
