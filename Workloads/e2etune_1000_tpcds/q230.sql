WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_promo_sk
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year > 1950
)
SELECT
    fs.ss_store_sk AS store_sk,
    CONCAT(CAST(d.d_year AS VARCHAR), '-', LPAD(CAST(d.d_moy AS VARCHAR), 2, '0')) AS year_month,
    p.p_promo_name,
    SUM(fs.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(r.sr_net_loss), 0) AS total_returns_loss,
    SUM(fs.ss_net_profit) - COALESCE(SUM(r.sr_net_loss), 0) AS net_profit_after_returns,
    SUM(fs.ss_ext_discount_amt) AS total_discount,
    CASE WHEN SUM(fs.ss_quantity) > 0 THEN SUM(fs.ss_ext_discount_amt) / SUM(fs.ss_quantity) ELSE 0 END AS avg_discount_per_sale,
    CASE WHEN SUM(fs.ss_quantity) > 0 THEN COALESCE(SUM(r.sr_return_quantity), 0) / SUM(fs.ss_quantity) ELSE 0 END AS return_rate
FROM filtered_sales fs
LEFT JOIN store_returns r
    ON fs.ss_ticket_number = r.sr_ticket_number
   AND fs.ss_item_sk = r.sr_item_sk
JOIN date_dim d
    ON fs.ss_sold_date_sk = d.d_date_sk
JOIN promotion p
    ON fs.ss_promo_sk = p.p_promo_sk
WHERE p.p_discount_active = 'Y'
  AND d.d_year BETWEEN 2000 AND 2002
GROUP BY fs.ss_store_sk, d.d_year, d.d_moy, p.p_promo_name
ORDER BY total_sales_profit DESC
LIMIT 100
