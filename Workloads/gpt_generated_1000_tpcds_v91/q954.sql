WITH catalog_profit AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_quantity > (SELECT AVG(cs2.cs_quantity) FROM catalog_sales cs2)
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
return_items AS (
    SELECT DISTINCT i.i_item_sk
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_return_quantity > 0
),
items_without_returns AS (
    SELECT cp.i_item_sk
    FROM catalog_profit cp
    EXCEPT
    SELECT ri.i_item_sk
    FROM return_items ri
)
SELECT
    cp.i_item_id,
    cp.i_product_name,
    cp.total_profit,
    cp.sales_cnt,
    RANK() OVER (ORDER BY cp.total_profit DESC) AS profit_rank,
    (SELECT MAX(cs.cs_sold_date_sk) FROM catalog_sales cs WHERE cs.cs_item_sk = cp.i_item_sk) AS latest_sold_date_sk,
    (SELECT AVG(total_profit) FROM catalog_profit) AS avg_total_profit_all
FROM catalog_profit cp
JOIN items_without_returns iwr
    ON cp.i_item_sk = iwr.i_item_sk
WHERE cp.total_profit > (SELECT AVG(cp2.total_profit) FROM catalog_profit cp2)
ORDER BY cp.total_profit DESC
LIMIT 20
