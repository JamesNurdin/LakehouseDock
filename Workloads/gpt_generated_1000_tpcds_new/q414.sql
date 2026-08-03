WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        SUM(cs.cs_net_paid)                AS total_net_paid,
        SUM(cs.cs_quantity)                AS total_qty,
        ARRAY_AGG(cs.cs_quantity)          AS qty_array
    FROM catalog_sales cs
    GROUP BY cs.cs_order_number
),
order_set AS (
    (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 1914
        UNION DISTINCT
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 1919
    )
    EXCEPT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
)
SELECT
    os.cs_order_number                AS order_number,
    sa.total_net_paid,
    sa.total_qty,
    d_sold.d_year                     AS sold_year,
    sm_sales.sm_type                  AS ship_type,
    w_sales.w_warehouse_name          AS warehouse_name,
    qty_exp.qty                       AS quantity_item
FROM order_set os
JOIN sales_agg sa               ON os.cs_order_number = sa.cs_order_number
JOIN catalog_sales cs           ON cs.cs_order_number = os.cs_order_number
JOIN date_dim d_sold            ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship            ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm_sales         ON cs.cs_ship_mode_sk = sm_sales.sm_ship_mode_sk
JOIN warehouse w_sales          ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
JOIN catalog_returns cr        ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_return          ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN ship_mode sm_return        ON cr.cr_ship_mode_sk = sm_return.sm_ship_mode_sk
JOIN warehouse w_return         ON cr.cr_warehouse_sk = w_return.w_warehouse_sk
CROSS JOIN UNNEST(sa.qty_array) WITH ORDINALITY AS qty_exp(qty, idx)
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = cs.cs_order_number
      AND cr2.cr_fee > 0
)
ORDER BY sa.total_net_paid DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
