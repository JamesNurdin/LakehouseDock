WITH sales_filtered AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_sold_time_sk,
        i.i_manufact,
        i.i_brand,
        i.i_color,
        i.i_item_desc,
        p.p_promo_name
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '\\d')
      AND i.i_color LIKE 're%'
      AND (p.p_promo_name LIKE '%sale%' OR regexp_like(p.p_promo_name, '^.*discount.*$'))
)
SELECT
    sf.i_manufact AS manufacturer,
    sf.i_brand AS brand,
    CONCAT(sf.i_brand, '-', sf.i_manufact) AS brand_manufact,
    td.t_hour AS hour_of_day,
    CASE WHEN td.t_hour < 12 THEN 'Morning' ELSE 'Afternoon' END AS time_of_day,
    COUNT(*) AS num_sales,
    SUM(sf.ss_ext_sales_price) AS total_sales_amount,
    SUM(sf.ss_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(sf.ss_net_profit) > 100000 THEN 'High'
        WHEN SUM(sf.ss_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    MAX(REGEXP_EXTRACT(sf.i_item_desc, '(\\d+)')) AS extracted_number_max,
    MIN(CONCAT('Item: ', sf.i_item_desc)) AS sample_desc
FROM sales_filtered sf
JOIN time_dim td ON sf.ss_sold_time_sk = td.t_time_sk
GROUP BY
    sf.i_manufact,
    sf.i_brand,
    td.t_hour
ORDER BY total_net_profit DESC
LIMIT 100
