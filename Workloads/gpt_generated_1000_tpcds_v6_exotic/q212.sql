WITH sales_data AS (
    SELECT
        ss.ss_customer_sk AS c_customer_sk,
        c.c_email_address,
        hd.hd_vehicle_count,
        ss.ss_ext_sales_price,
        sr.sr_net_loss
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
)
SELECT
    regexp_extract(c_email_address, '@([^\\.]+\\..+)$', 1) AS email_domain,
    CASE
        WHEN hd_vehicle_count >= 3 THEN 'Many Vehicles'
        ELSE 'Few Vehicles'
    END AS vehicle_category,
    sum(ss_ext_sales_price) AS total_sales,
    sum(coalesce(sr_net_loss, 0)) AS total_return_loss,
    count(DISTINCT c_customer_sk) AS distinct_customers
FROM sales_data
WHERE regexp_like(c_email_address, '^[A-Za-z]+\\.[A-Za-z]+@')
  AND c_email_address LIKE '%.com'
GROUP BY
    regexp_extract(c_email_address, '@([^\\.]+\\..+)$', 1),
    CASE
        WHEN hd_vehicle_count >= 3 THEN 'Many Vehicles'
        ELSE 'Few Vehicles'
    END
HAVING sum(ss_ext_sales_price) > 1000
   AND count(DISTINCT c_customer_sk) > 5
ORDER BY total_sales DESC
