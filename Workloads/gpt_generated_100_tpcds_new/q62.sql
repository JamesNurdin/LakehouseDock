WITH filtered_sales AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        i.i_item_desc,
        i.i_product_name,
        p.p_promo_name,
        d.d_year,
        CONCAT('Order_', CAST(cs.cs_order_number AS VARCHAR)) AS order_id_str
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_item_desc, '(?i).*(SPORT|ELECTRO).*')
      AND p.p_promo_name LIKE '%discount%'
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(fs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
    MIN(fs.d_year) AS first_year,
    MAX(fs.d_year) AS last_year,
    SUBSTRING(fs.i_item_desc FROM 1 FOR 30) AS item_desc_snippet,
    REGEXP_EXTRACT(fs.p_promo_name, '(\\d+)%') AS promo_percent
FROM filtered_sales fs
JOIN customer c ON fs.cs_bill_customer_sk = c.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
      AND wr.wr_refunded_cash > 500
)
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    fs.i_item_desc,
    fs.p_promo_name,
    fs.d_year
ORDER BY total_net_profit DESC
LIMIT 100
