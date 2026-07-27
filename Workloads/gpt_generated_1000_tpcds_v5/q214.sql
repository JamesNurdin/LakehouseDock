WITH sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        p.p_purpose AS promo_purpose,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS transaction_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_qoy = 2
      AND d.d_dom IN (6, 12, 17)
      AND p.p_channel_catalog = 'N'
      AND ca.ca_city = 'Fairview'
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
    GROUP BY s.s_store_id, p.p_purpose
)
SELECT
    store_id,
    AVG(total_sales) AS avg_sales_per_purpose,
    SUM(total_profit) AS sum_profit,
    COUNT(*) AS purpose_count
FROM sales_agg
GROUP BY store_id
HAVING SUM(total_profit) > 1000
ORDER BY avg_sales_per_purpose DESC
LIMIT 100
