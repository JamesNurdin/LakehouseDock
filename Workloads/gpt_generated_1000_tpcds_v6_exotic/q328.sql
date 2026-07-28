WITH sales_with_promo AS (
    SELECT
        ws.ws_bill_customer_sk      AS customer_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_sold_date_sk,
        p.p_promo_name,
        d.d_year,
        CASE
            WHEN regexp_like(p.p_promo_name, '^Summer.*') THEN 'Summer'
            WHEN regexp_like(p.p_promo_name, 'Clearance') THEN 'Clearance'
            ELSE 'Other'
        END AS promo_category,
        regexp_extract(p.p_promo_name, '(\\d{4})') AS promo_year_extracted
    FROM web_sales ws
    JOIN promotion p      ON ws.ws_promo_sk   = p.p_promo_sk
    JOIN date_dim d       ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND (p.p_promo_name LIKE '%Discount%' OR p.p_promo_name LIKE '%Sale%')
)
SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    swp.promo_category,
    COUNT(DISTINCT swp.ws_order_number) AS num_orders,
    SUM(swp.ws_net_paid)               AS total_net_paid,
    AVG(swp.ws_sales_price)            AS avg_sales_price,
    MAX(swp.promo_year_extracted)      AS latest_promo_year
FROM sales_with_promo swp
JOIN customer c
    ON swp.customer_sk = c.c_customer_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_order_number = swp.ws_order_number
      AND wr.wr_item_sk      = swp.ws_item_sk
)
GROUP BY
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name),
    swp.promo_category
ORDER BY total_net_paid DESC
LIMIT 100
