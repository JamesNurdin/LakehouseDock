WITH sales AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS metric_amount,
        SUM(cs.cs_quantity) AS quantity,
        inv.inv_quantity_on_hand,
        'sales' AS metric_type
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    FULL OUTER JOIN inventory inv 
        ON i.i_item_sk = inv.inv_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq, inv.inv_quantity_on_hand
),
returns AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS metric_amount,
        SUM(cr.cr_return_quantity) AS quantity,
        inv.inv_quantity_on_hand,
        'returns' AS metric_type
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    FULL OUTER JOIN inventory inv 
        ON i.i_item_sk = inv.inv_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq, inv.inv_quantity_on_hand
),
combined AS (
    SELECT 
        metric_type,
        i_item_id,
        i_product_name,
        d_year,
        d_month_seq,
        metric_amount,
        quantity,
        inv_quantity_on_hand
    FROM sales
    UNION ALL
    SELECT 
        metric_type,
        i_item_id,
        i_product_name,
        d_year,
        d_month_seq,
        metric_amount,
        quantity,
        inv_quantity_on_hand
    FROM returns
)
SELECT 
    c.metric_type,
    c.i_item_id,
    c.i_product_name,
    c.d_year,
    c.d_month_seq,
    c.metric_amount,
    c.quantity,
    c.inv_quantity_on_hand,
    (
        SELECT COUNT(DISTINCT cs2.cs_bill_customer_sk)
        FROM catalog_sales cs2
        JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
        WHERE i2.i_item_id = c.i_item_id
    ) AS distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY c.metric_type ORDER BY c.metric_amount DESC) AS metric_rank,
    ROW_NUMBER() OVER (PARTITION BY c.i_item_id ORDER BY c.metric_amount DESC) AS item_rank
FROM combined c
ORDER BY c.metric_amount DESC
LIMIT 100
