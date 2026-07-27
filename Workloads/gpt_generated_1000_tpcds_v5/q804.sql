WITH sales_joined AS (
    SELECT
        ca.ca_county,
        ca.ca_gmt_offset,
        hd.hd_vehicle_count,
        ss.ss_net_paid,
        ss.ss_ext_tax
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_gmt_offset = -5.00
      AND ca.ca_county IN ('Richland County', 'Washington County')
      AND hd.hd_vehicle_count >= 1
      AND ss.ss_ext_tax > 0
)
SELECT
    ca_county,
    COUNT(*) AS transaction_count,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_ext_tax) AS total_tax,
    RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS county_rank,
    CASE
        WHEN SUM(ss_net_paid) > 10000 THEN 'High'
        WHEN SUM(ss_net_paid) > 5000  THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM sales_joined
GROUP BY ca_county
ORDER BY county_rank
