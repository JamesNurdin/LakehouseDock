WITH sales_with_filters AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_item_sk
    FROM store_sales ss
    WHERE ss.ss_net_profit > 0
      AND ss.ss_quantity >= 1
),
avg_year_profit AS (
    SELECT d.d_year,
           AVG(ss2.ss_net_profit) AS avg_profit_year
    FROM store_sales ss2
    JOIN date_dim d ON ss2.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year
)
SELECT
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    CASE
        WHEN ssf.ss_net_profit >= 1000 THEN 'High'
        WHEN ssf.ss_net_profit >= 100 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    SUM(ssf.ss_net_paid) AS total_net_paid,
    AVG(ssf.ss_net_profit) AS avg_net_profit,
    COUNT(*) AS sales_count,
    (SELECT avg_profit_year FROM avg_year_profit WHERE d_year = d.d_year) AS year_avg_profit
FROM sales_with_filters ssf
JOIN date_dim d ON ssf.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ssf.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd ON ssf.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON ssf.ss_addr_sk = ca.ca_address_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE s.s_state = 'CA'
  AND d.d_year = 2000
  AND w.w_city = 'Seattle'
  AND i.inv_quantity_on_hand > 500
GROUP BY
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    CASE
        WHEN ssf.ss_net_profit >= 1000 THEN 'High'
        WHEN ssf.ss_net_profit >= 100 THEN 'Medium'
        ELSE 'Low'
    END,
    (SELECT avg_profit_year FROM avg_year_profit WHERE d_year = d.d_year)
ORDER BY total_net_paid DESC
LIMIT 100
