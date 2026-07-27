/* goal: Identify high‑value customers by combining their sales and return activities, enriched with warehouse inventory, promotion, and web page information, applying multiple filters, a UNION set operation, a scalar EXISTS subquery, and a window ranking */
WITH sales_data AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ticket_number,
        p.p_promo_id,
        t.t_hour,
        c.c_customer_id
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_quantity > 5
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
),
returns_data AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_ticket_number,
        t.t_hour,
        c.c_customer_id
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_ship_cost > 50
      AND t.t_hour BETWEEN 9 AND 17
),
unified AS (
    SELECT
        ss_customer_sk AS customer_sk,
        ss_sold_date_sk AS date_sk,
        ss_sold_time_sk AS time_sk,
        ss_quantity AS quantity,
        ss_net_paid AS amount,
        'sale' AS src
    FROM sales_data
    UNION ALL
    SELECT
        sr_customer_sk,
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_return_quantity,
        sr_return_amt,
        'return' AS src
    FROM returns_data
),
warehouse_inventory AS (
    SELECT
        w.w_warehouse_sk,
        w.w_state,
        w.w_city,
        inv.inv_quantity_on_hand
    FROM warehouse w
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
)
SELECT
    c.c_customer_id,
    COALESCE(u.src, 'none') AS activity_type,
    SUM(u.amount) AS total_amount,
    COUNT(*) FILTER (WHERE u.src = 'sale') AS sales_cnt,
    COUNT(*) FILTER (WHERE u.src = 'return') AS returns_cnt,
    MAX(u.amount) AS max_amount,
    MIN(u.amount) AS min_amount,
    AVG(u.amount) AS avg_amount,
    w_inv.inv_quantity_on_hand,
    wp.wp_url,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(u.amount) DESC) AS rn
FROM unified u
LEFT JOIN catalog_returns cr
    ON u.customer_sk = cr.cr_refunded_customer_sk
LEFT JOIN customer c
    ON u.customer_sk = c.c_customer_sk
LEFT JOIN warehouse_inventory w_inv
    ON cr.cr_warehouse_sk = w_inv.w_warehouse_sk
LEFT JOIN web_page wp
    ON c.c_customer_sk = wp.wp_customer_sk
WHERE c.c_birth_year BETWEEN 1970 AND 1990
  AND (cr.cr_return_amount > 100 OR cr.cr_return_amount IS NULL)
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_type = 'article'
    )
GROUP BY
    c.c_customer_id,
    u.src,
    w_inv.inv_quantity_on_hand,
    wp.wp_url
HAVING SUM(u.amount) > 1000
ORDER BY total_amount DESC
LIMIT 100
