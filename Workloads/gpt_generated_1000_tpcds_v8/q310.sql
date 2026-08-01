WITH sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    d_sold.d_year AS sold_year,
    i.i_item_id,
    i.i_product_name,
    ws.ws_quantity,
    ws.ws_net_paid,
    CASE
        WHEN ws.ws_net_profit > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_indicator,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_net_paid DESC) AS rn_customer,
    RANK() OVER (ORDER BY ws.ws_net_paid DESC) AS global_sales_rank,
    latest_promo.p_promo_name AS latest_promo_name
FROM sampled_sales ws
FULL OUTER JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
CROSS JOIN LATERAL (
    SELECT p2.p_promo_name
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
    ORDER BY p2.p_start_date_sk DESC
    LIMIT 1
) latest_promo
WHERE
    c.c_birth_month IN (1, 2, 3, 4, 5, 6)                       -- predicate 1
    AND ca.ca_state = 'CA'                                    -- predicate 2
    AND d_sold.d_year BETWEEN 2000 AND 2002                    -- predicate 3
    AND i.i_current_price > 20.00                             -- predicate 4
    AND sm.sm_type = 'AIR'                                     -- predicate 5
    AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_type = 'home'
    )                                                         -- predicate 6 (semi‑join)
    AND c.c_customer_sk NOT IN (
        SELECT ws2.ws_bill_customer_sk
        FROM web_sales ws2
        WHERE ws2.ws_quantity > 1000
    )                                                         -- anti‑semi‑join
ORDER BY ws.ws_net_paid DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
