/*
Goal: Identify items that were both sold in stores and returned online, compute sales and return metrics, and combine this with a summary of high‑frequency store transactions per item. The query uses CTEs, INTERSECT, UNION ALL, a LATERAL subquery, a CROSS JOIN with a tiny constant table, IN‑subquery filtering, GROUP BY HAVING, and ends with LIMIT 100.
*/
WITH sold_items AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_quantity)                                   AS total_qty,
        SUM(ss.ss_ext_sales_price)                            AS total_sales,
        COUNT(*)                                              AS sales_txns
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY i.i_item_sk, i.i_product_name
    HAVING SUM(ss.ss_ext_sales_price) > 10000
),
returned_items AS (
    SELECT
        i.i_item_sk,
        SUM(wr.wr_return_quantity)          AS total_ret_qty,
        SUM(wr.wr_return_amt_inc_tax)       AS total_ret_amt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
),
intersect_items AS (
    SELECT i_item_sk FROM sold_items
    INTERSECT
    SELECT i_item_sk FROM returned_items
),
first_part AS (
    SELECT
        si.i_item_sk                                           AS item_sk,
        si.i_product_name                                      AS description,
        CAST(si.total_sales AS DOUBLE)                         AS metric_a,
        CAST(ri.total_ret_amt AS DOUBLE)                       AS metric_b,
        CAST(td.t_hour AS VARCHAR)                             AS attr,
        const.const_val
    FROM intersect_items ii
    JOIN sold_items si      ON ii.i_item_sk = si.i_item_sk
    JOIN returned_items ri  ON ii.i_item_sk = ri.i_item_sk
    JOIN time_dim td        ON td.t_time_sk = (
        SELECT MIN(ss2.ss_sold_time_sk)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = si.i_item_sk
    )
    CROSS JOIN (SELECT 'A' AS const_val) const
),
second_part AS (
    SELECT
        i.i_item_sk                                            AS item_sk,
        i.i_brand                                              AS description,
        CAST(COUNT(DISTINCT ss.ss_ticket_number) AS DOUBLE)   AS metric_a,
        CAST(NULL AS DOUBLE)                                   AS metric_b,
        td.t_shift                                             AS attr,
        const.const_val
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    CROSS JOIN (SELECT 'B' AS const_val) const
    LEFT JOIN LATERAL (
        SELECT AVG(ss2.ss_ext_discount_amt) AS avg_disc
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
    ) ld ON true
    WHERE i.i_item_sk IN (
        SELECT i2.i_item_sk FROM item i2 WHERE i2.i_brand = 'BrandX'
    )
    GROUP BY i.i_item_sk, i.i_brand, td.t_shift, const.const_val
    HAVING COUNT(DISTINCT ss.ss_ticket_number) > 5
)
SELECT item_sk, description, metric_a, metric_b, attr, const_val
FROM first_part
UNION ALL
SELECT item_sk, description, metric_a, metric_b, attr, const_val
FROM second_part
LIMIT 100
