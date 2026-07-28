WITH promo_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_details,
        d_start.d_date AS start_date,
        d_end.d_date   AS end_date
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk = d_end.d_date_sk
    WHERE regexp_like(p.p_channel_details, '(?i)old')
      AND p.p_promo_name LIKE '%Sale%'
)
SELECT
    d_sold.d_year                                          AS sales_year,
    CONCAT(pf.p_promo_name, ' - ', CAST(d_sold.d_month_seq AS VARCHAR)) AS promo_month_key,
    SUBSTRING(pf.p_promo_name, 1, 10)                     AS short_name,
    SUM(cs.cs_ext_sales_price)                            AS total_sales,
    SUM(cs.cs_net_profit)                                 AS total_profit
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN promo_filtered pf ON cs.cs_promo_sk = pf.p_promo_sk
WHERE d_sold.d_date BETWEEN pf.start_date AND pf.end_date
GROUP BY
    d_sold.d_year,
    CONCAT(pf.p_promo_name, ' - ', CAST(d_sold.d_month_seq AS VARCHAR)),
    SUBSTRING(pf.p_promo_name, 1, 10)
ORDER BY total_profit DESC
LIMIT 10
