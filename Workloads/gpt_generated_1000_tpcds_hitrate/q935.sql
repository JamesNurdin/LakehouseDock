/*
Goal: Compare total sales and total returns for each store in the year 2001, classify the totals as High or Low based on the overall average net paid amount from a sampled slice of store_sales, retain stores without any sales or returns (right outer joins), and provide subtotals per store and a grand total using GROUP BY ROLLUP. The result combines sales and returns rows via UNION ALL, includes an EXISTS filter on inventory, and is limited to the top 100 rows.
*/
WITH sales_data AS (
    SELECT
        s.s_store_id AS store_id,
        'sales' AS txn_type,
        SUM(ss.ss_net_paid) AS amount
    FROM store_sales ss
    RIGHT OUTER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE (d.d_year = 2001 OR d.d_year IS NULL)
      AND EXISTS (
          SELECT 1 FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY s.s_store_id
),
returns_data AS (
    SELECT
        s.s_store_id AS store_id,
        'return' AS txn_type,
        SUM(sr.sr_return_amt_inc_tax) AS amount
    FROM store_returns sr
    RIGHT OUTER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE (d.d_year = 2001 OR d.d_year IS NULL)
      AND EXISTS (
          SELECT 1 FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY s.s_store_id
),
union_data AS (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM returns_data
)
SELECT
    store_id,
    txn_type,
    SUM(amount) AS total_amount,
    CASE WHEN SUM(amount) > (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        TABLESAMPLE BERNOULLI (10)
    ) THEN 'High' ELSE 'Low' END AS amount_category
FROM union_data
GROUP BY ROLLUP (store_id, txn_type)
ORDER BY store_id ASC NULLS LAST, txn_type
LIMIT 100
