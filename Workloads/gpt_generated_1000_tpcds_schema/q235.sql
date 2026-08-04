WITH sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),
promotion_items AS (
    SELECT p.p_promo_sk, p.p_item_sk, p.p_discount_active
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
intersect_keys AS (
    SELECT i.i_item_sk
    FROM item i
    WHERE i.i_color = 'red'
    INTERSECT
    SELECT pi.p_item_sk
    FROM promotion_items pi
),
full_item_inventory AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        si.inv_quantity_on_hand
    FROM item i
    FULL OUTER JOIN sampled_inventory si
        ON si.inv_item_sk = i.i_item_sk
),
web_base AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_net_paid_inc_tax,
        ws.ws_quantity
    FROM web_sales ws
    JOIN full_item_inventory fii
        ON ws.ws_item_sk = fii.i_item_sk
    INNER JOIN intersect_keys ik
        ON ik.i_item_sk = ws.ws_item_sk
)
SELECT
    wsite.web_city,
    td.t_meal_time,
    i.i_category,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales,
    SUM(COALESCE(inv_agg.total_qty, 0)) AS total_inventory,
    COUNT(DISTINCT c_bill.c_customer_id) AS distinct_customers
FROM web_base ws
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer c_ship
    ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN LATERAL (
    SELECT SUM(inv_quantity_on_hand) AS total_qty
    FROM sampled_inventory si2
    WHERE si2.inv_item_sk = i.i_item_sk
) AS inv_agg ON TRUE
GROUP BY
    wsite.web_city,
    td.t_meal_time,
    i.i_category
ORDER BY total_sales DESC
LIMIT 100
