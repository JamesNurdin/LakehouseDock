/*
Goal: Produce a monthly inventory summary per warehouse for the year 2021, focusing on warehouses whose city starts with "P" and whose street name contains the word "Park". The query demonstrates string processing (LIKE, regexp_like, CONCAT, SUBSTRING), uses a scalar subquery to count customers with @example.com email addresses who reviewed on the same year, applies a HAVING filter on total quantity, and orders the results by total quantity.
*/
WITH inv_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        d.d_month_seq,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        (
            SELECT COUNT(*)
            FROM customer c
            JOIN date_dim cd ON c.c_last_review_date = cd.d_date_sk
            WHERE cd.d_year = d.d_year
              AND regexp_like(c.c_email_address, '@example\\.com$')
        ) AS review_customer_cnt
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city LIKE 'P%'
      AND regexp_like(w.w_street_name, '.*Park.*')
      AND d.d_year = 2021
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, w.w_city, d.d_month_seq, d.d_year
    HAVING SUM(i.inv_quantity_on_hand) > 1000
)
SELECT
    CONCAT(w_warehouse_name, ' - ', w_city) AS warehouse_label,
    SUBSTRING(w_warehouse_name, 1, 3) AS short_name,
    d_month_seq,
    total_qty,
    distinct_items,
    review_customer_cnt
FROM inv_agg
WHERE review_customer_cnt > 5
ORDER BY total_qty DESC, warehouse_label
