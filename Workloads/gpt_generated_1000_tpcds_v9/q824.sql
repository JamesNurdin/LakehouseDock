WITH
    regex_items AS (
        SELECT
            i_item_sk,
            i_product_name,
            substring(i_product_name, 1, 10) AS prod_name_prefix
        FROM item
        WHERE regexp_like(i_product_name, '(?i)premium|pro')
    ),
    filtered_sales AS (
        SELECT
            ss.ss_item_sk AS item_sk,
            concat(s.s_store_name, ' - ', s.s_city) AS store_full_name,
            ss.ss_net_profit
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        WHERE s.s_state LIKE 'A%'
          AND td.t_shift = 'first'
    ),
    item_returns AS (
        SELECT
            sr.sr_item_sk AS item_sk,
            SUM(sr.sr_return_quantity) AS total_return_qty,
            COUNT(*) AS return_count
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE r.r_reason_desc LIKE '%defect%'
        GROUP BY sr.sr_item_sk
    ),
    union_items AS (
        SELECT i_item_sk AS item_sk
        FROM item
        WHERE regexp_like(i_item_desc, '(?i)special|exclusive')
        UNION
        SELECT sr_item_sk AS item_sk
        FROM store_returns
        WHERE sr_return_quantity > 5
    ),
    avg_profit_scalar AS (
        SELECT AVG(ss_net_profit) AS avg_net_profit
        FROM store_sales
    )
SELECT
    ri.i_item_sk,
    ri.i_product_name,
    ri.prod_name_prefix,
    fs.store_full_name,
    SUM(fs.ss_net_profit) AS total_net_profit,
    COALESCE(ir.total_return_qty, 0) AS total_return_qty,
    CASE
        WHEN SUM(fs.ss_net_profit) > (SELECT avg_net_profit FROM avg_profit_scalar) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS profit_category
FROM regex_items ri
JOIN filtered_sales fs ON ri.i_item_sk = fs.item_sk
LEFT JOIN item_returns ir ON ri.i_item_sk = ir.item_sk
WHERE ri.i_item_sk IN (SELECT item_sk FROM union_items)
GROUP BY
    ri.i_item_sk,
    ri.i_product_name,
    ri.prod_name_prefix,
    fs.store_full_name,
    ir.total_return_qty

UNION

SELECT
    ri.i_item_sk,
    ri.i_product_name,
    ri.prod_name_prefix,
    fs.store_full_name,
    0.0 AS total_net_profit,
    COALESCE(ir.total_return_qty, 0) AS total_return_qty,
    'NO_SALES' AS profit_category
FROM regex_items ri
JOIN filtered_sales fs ON ri.i_item_sk = fs.item_sk
LEFT JOIN item_returns ir ON ri.i_item_sk = ir.item_sk
WHERE ri.i_item_sk NOT IN (SELECT item_sk FROM union_items)
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = ri.i_item_sk
          AND sr.sr_return_quantity > 0
    )
GROUP BY
    ri.i_item_sk,
    ri.i_product_name,
    ri.prod_name_prefix,
    fs.store_full_name,
    ir.total_return_qty
