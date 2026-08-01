WITH item_returns AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_item_desc,
        SUM(sr.sr_return_amt) AS store_return_amount,
        COALESCE(SUM(wr.wr_return_amt), 0) AS web_return_amount
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_product_name, i.i_item_desc
)
SELECT
    ir.i_item_sk,
    ir.i_product_name,
    ir.i_item_desc,
    ir.store_return_amount,
    ir.web_return_amount,
    CASE
        WHEN ir.store_return_amount > ir.web_return_amount THEN 'Store Higher'
        WHEN ir.store_return_amount < ir.web_return_amount THEN 'Web Higher'
        ELSE 'Equal'
    END AS return_source,
    (
        SELECT AVG(ir2.store_return_amount + ir2.web_return_amount)
        FROM item_returns ir2
        WHERE ir2.i_product_name = ir.i_product_name
    ) AS avg_total_return_for_product,
    regexp_extract(ir.i_product_name, '^([A-Za-z]+)', 1) AS first_word,
    CONCAT('Prod-', CAST(ir.i_item_sk AS VARCHAR)) AS product_code,
    SUBSTRING(ir.i_product_name FROM 1 FOR 3) AS product_name_prefix
FROM item_returns ir
WHERE
    regexp_like(ir.i_item_desc, '[0-9]')                     -- description contains a digit
    AND ir.i_product_name LIKE 'A%'                         -- product name starts with 'A'
    AND ir.i_item_sk NOT IN (SELECT cr.cr_item_sk FROM catalog_returns cr) -- anti‑semi‑join
    AND EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_item_sk = ir.i_item_sk
          AND ws.ws_sold_time_sk = (
                SELECT MAX(t.t_time_sk)
                FROM time_dim t
                WHERE t.t_meal_time = 'dinner'
          )
    )
ORDER BY ir.store_return_amount DESC
LIMIT 100
