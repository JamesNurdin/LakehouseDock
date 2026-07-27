WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS cnt_records
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_warehouse_sk IN (1, 2, 3)
      AND inv_item_sk IN (101422, 101410, 101432)
    GROUP BY inv_date_sk, inv_item_sk, inv_warehouse_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_cust.d_date,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_size,
    i.i_container,
    ia.total_qty,
    ia.cnt_records,
    AVG(i.i_current_price) OVER (PARTITION BY i.i_category) AS avg_price_by_category
FROM customer c
JOIN date_dim d_cust
    ON c.c_first_shipto_date_sk = d_cust.d_date_sk
JOIN inv_agg ia
    ON ia.inv_date_sk = d_cust.d_date_sk
JOIN item i
    ON ia.inv_item_sk = i.i_item_sk
WHERE d_cust.d_year = 1998
  AND d_cust.d_month_seq BETWEEN 1200 AND 1210
  AND i.i_category = 'Shoes'
  AND i.i_size = 'medium'
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_year BETWEEN 1960 AND 1970
ORDER BY ia.total_qty DESC
LIMIT 100
