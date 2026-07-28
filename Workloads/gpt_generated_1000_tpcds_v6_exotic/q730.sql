WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_ship_cost,
        d_ret.d_year               AS return_year,
        i.i_brand,
        i.i_category,
        s.s_store_id,
        s.s_store_name,
        c.c_customer_id,
        c.c_birth_year,
        d_first_sales.d_year      AS first_sales_year,
        d_ship.d_year             AS first_ship_year,
        inv_ship.inv_quantity_on_hand AS ship_inventory_qty,
        inv_ret.inv_quantity_on_hand  AS ret_inventory_qty
    FROM store_returns sr
    INNER JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    INNER JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    INNER JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    INNER JOIN date_dim d_first_sales
        ON c.c_first_sales_date_sk = d_first_sales.d_date_sk
    INNER JOIN date_dim d_ship
        ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    INNER JOIN inventory inv_ship
        ON inv_ship.inv_date_sk = d_ship.d_date_sk
        AND inv_ship.inv_item_sk = i.i_item_sk
    LEFT JOIN inventory inv_ret
        ON inv_ret.inv_date_sk = d_ret.d_date_sk
        AND inv_ret.inv_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
)
SELECT
    b.s_store_id,
    b.i_brand,
    b.return_year,
    SUM(b.sr_return_amt)                           AS total_return_amount,
    AVG(b.sr_return_tax)                           AS avg_return_tax,
    COUNT(DISTINCT b.c_customer_id)                AS distinct_customers,
    SUM(CASE WHEN b.ret_inventory_qty IS NULL THEN 1 ELSE 0 END) AS returns_without_inventory,
    ROW_NUMBER() OVER (PARTITION BY b.s_store_id ORDER BY SUM(b.sr_return_amt) DESC) AS store_return_rank
FROM base b
WHERE EXISTS (
    SELECT 1
    FROM inventory inv_chk
    WHERE inv_chk.inv_item_sk = b.sr_item_sk
      AND inv_chk.inv_quantity_on_hand > 0
)
GROUP BY ROLLUP (b.s_store_id, b.i_brand, b.return_year)
HAVING SUM(b.sr_return_amt) > 0
ORDER BY total_return_amount DESC
LIMIT 100
