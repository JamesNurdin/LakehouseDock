WITH promo_items AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        i.i_item_sk,
        i.i_item_desc,
        regexp_extract(i.i_item_desc, '(\\d+)', 1) AS item_number
    FROM promotion p
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{4}')
      AND p.p_promo_name LIKE '%Discount%'
)
SELECT
    concat(pi.p_promo_name, ' - ', pi.item_number) AS promo_item_label,
    d.d_year,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN promo_items pi
    ON ws.ws_promo_sk = pi.p_promo_sk
   AND ws.ws_item_sk = pi.i_item_sk
WHERE d.d_year BETWEEN 2001 AND 2003
  AND substring(pi.p_promo_name, 1, 3) = 'Dis'
GROUP BY pi.p_promo_name,
         pi.item_number,
         d.d_year,
         concat(pi.p_promo_name, ' - ', pi.item_number)
ORDER BY total_net_paid DESC
LIMIT 100
