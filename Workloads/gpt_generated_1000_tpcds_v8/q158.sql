/* goal: Compare high‑value store vs catalog sales by hour, rank them within each day, and combine the results */
WITH store_data AS (
    SELECT
        ss.ss_sold_date_sk AS sale_date_sk,
        td.t_hour AS hour_of_day,
        ss.ss_net_paid AS net_amount,
        'store' AS sale_type,
        CASE WHEN ss.ss_net_paid > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_sold_date_sk ORDER BY ss.ss_net_paid DESC) AS rank_in_day,
        (SELECT avg(ss2.ss_net_paid) FROM store_sales ss2) AS avg_store_net
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ca.ca_state = 'CA'
      AND EXISTS (
            SELECT 1
            FROM customer_demographics cd
            WHERE cd.cd_demo_sk = ss.ss_cdemo_sk
              AND cd.cd_credit_rating = 'Excellent'
        )
),
catalog_data AS (
    SELECT
        cs.cs_sold_date_sk AS sale_date_sk,
        td.t_hour AS hour_of_day,
        cs.cs_net_paid AS net_amount,
        'catalog' AS sale_type,
        CASE WHEN cs.cs_net_paid > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_sold_date_sk ORDER BY cs.cs_net_paid DESC) AS rank_in_day,
        (SELECT avg(cs2.cs_net_paid) FROM catalog_sales cs2) AS avg_catalog_net
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ca.ca_country = 'United States'
      AND EXISTS (
            SELECT 1
            FROM call_center cc
            WHERE cc.cc_call_center_sk = cs.cs_call_center_sk
              AND cc.cc_gmt_offset = -5.00
        )
)
SELECT
    combined.sale_date_sk,
    combined.hour_of_day,
    combined.net_amount,
    combined.sale_type,
    combined.amount_category,
    combined.rank_in_day
FROM (
    SELECT sale_date_sk, hour_of_day, net_amount, sale_type, amount_category, rank_in_day
    FROM store_data
    UNION ALL
    SELECT sale_date_sk, hour_of_day, net_amount, sale_type, amount_category, rank_in_day
    FROM catalog_data
) AS combined
ORDER BY combined.sale_date_sk DESC, combined.net_amount DESC
LIMIT 100
