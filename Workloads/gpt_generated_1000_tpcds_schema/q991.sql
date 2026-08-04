/* goal: compare net profit/loss from catalog sales/returns with inventory quantities for elite‑steel items in year 2001, applying regex and LIKE filters, and return a paginated ranked list */
WITH first_part AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        d.d_year,
        COALESCE(SUM(cs.cs_net_profit), 0) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_balance,
        'sales_return' AS source
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    JOIN item i
        ON COALESCE(cs.cs_item_sk, cr.cr_item_sk) = i.i_item_sk
    JOIN date_dim d
        ON COALESCE(cs.cs_sold_date_sk, cr.cr_returned_date_sk) = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_item_desc LIKE '%steel%'
      AND regexp_like(i.i_item_desc, '.*[Ee]lite.*')
    GROUP BY i.i_item_id, i.i_item_desc, i.i_category, d.d_year
),
second_part AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        d.d_year,
        SUM(inv.inv_quantity_on_hand) AS net_balance,
        'inventory' AS source
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_item_desc LIKE '%steel%'
      AND regexp_like(i.i_item_desc, '.*[Ee]lite.*')
    GROUP BY i.i_item_id, i.i_item_desc, i.i_category, d.d_year
),
unioned AS (
    SELECT * FROM first_part
    UNION DISTINCT
    SELECT * FROM second_part
)
SELECT
    u.i_item_id,
    u.i_item_desc,
    u.i_category,
    u.d_year,
    u.net_balance,
    u.source,
    concat(u.i_category, '-', CAST(u.d_year AS varchar)) AS cat_year,
    CASE
        WHEN regexp_extract(u.i_item_desc, '^([^ ]+)') = 'Steel' THEN 'Top'
        ELSE 'Other'
    END AS desc_group,
    lt.first_word
FROM unioned u
CROSS JOIN LATERAL (
    SELECT regexp_extract(u.i_item_desc, '^([^ ]+)') AS first_word
) lt
ORDER BY u.net_balance DESC, u.i_item_id
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY
