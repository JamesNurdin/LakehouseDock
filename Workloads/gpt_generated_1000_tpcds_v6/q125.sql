-- goal: Summarize store returns by product brand and customer credit category for morning returns (8‑12h) where the return reason matches a specific pattern and the product name contains 'PRO'.  Show return count, total net loss, average original sale price, the highest extracted reason code and a sample product name.
WITH returns_data AS (
    SELECT
        i.i_brand AS brand,
        i.i_product_name AS product_name,
        r.r_reason_desc AS reason_desc,
        cd.cd_credit_rating AS credit_rating,
        sr.sr_net_loss AS net_loss,
        ss.ss_ext_sales_price AS original_sales_price,
        td.t_hour AS hour_of_day,
        concat(i.i_brand, ' ', i.i_product_name) AS full_product_name,
        regexp_extract(r.r_reason_desc, '(\\d+)', 1) AS reason_code,
        CASE WHEN cd.cd_credit_rating = 'Good' THEN 'High Credit' ELSE 'Other' END AS credit_category
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
        AND ss.ss_item_sk = i.i_item_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND regexp_like(r.r_reason_desc, '^C[0-9]{2,}$')
      AND i.i_product_name LIKE '%PRO%'
)
SELECT
    brand,
    credit_category,
    COUNT(*) AS return_count,
    SUM(net_loss) AS total_net_loss,
    AVG(original_sales_price) AS avg_original_sale_price,
    MAX(reason_code) AS max_reason_code,
    MIN(full_product_name) AS sample_product_name
FROM returns_data
GROUP BY brand, credit_category
ORDER BY total_net_loss DESC
LIMIT 100
