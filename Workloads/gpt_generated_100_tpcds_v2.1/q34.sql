WITH sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        ca.ca_county AS county,
        ca.ca_location_type AS location_type,
        cd.cd_gender AS gender,
        td.t_hour AS hour,
        td.t_minute AS minute,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS transaction_count,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) > 0 THEN SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price)
            ELSE 0
        END AS profit_margin_ratio
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ca.ca_county IN ('Lipscomb County', 'Maricopa County')
      AND ca.ca_gmt_offset = -7.00
      AND ca.ca_location_type = 'apartment'
      AND s.s_manager = 'Ricky Nichols'
      AND s.s_rec_end_date >= DATE '1999-01-01'
      AND td.t_hour BETWEEN 9 AND 17
      AND td.t_minute IN (4, 15)
    GROUP BY s.s_store_id, s.s_store_name, ca.ca_county, ca.ca_location_type, cd.cd_gender, td.t_hour, td.t_minute
)
SELECT
    store_id,
    store_name,
    county,
    location_type,
    gender,
    AVG(total_sales) AS avg_sales_per_hour_minute,
    AVG(total_profit) AS avg_profit_per_hour_minute,
    SUM(transaction_count) AS total_transactions,
    AVG(profit_margin_ratio) AS avg_profit_margin_ratio,
    CASE
        WHEN AVG(profit_margin_ratio) > 0.1 THEN 'High Margin'
        WHEN AVG(profit_margin_ratio) > 0.0 THEN 'Low Margin'
        ELSE 'No Margin'
    END AS margin_category
FROM sales_agg
GROUP BY store_id, store_name, county, location_type, gender
HAVING SUM(transaction_count) >= 20
ORDER BY avg_sales_per_hour_minute DESC
LIMIT 100
