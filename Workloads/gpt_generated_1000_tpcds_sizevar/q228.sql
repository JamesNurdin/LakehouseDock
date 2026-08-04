WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM
        tpcds.inventory TABLESAMPLE BERNOULLI (50)
    WHERE
        inv_quantity_on_hand > 100
        AND inv_warehouse_sk BETWEEN 10 AND 20
        AND inv_item_sk IN (101425, 101449, 101419, 101432, 101443)
    GROUP BY
        inv_warehouse_sk
),
max_qty AS (
    SELECT MAX(inv_quantity_on_hand) AS max_qty
    FROM tpcds.inventory
    WHERE inv_warehouse_sk = 14
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_county,
    ia.total_qty,
    ia.distinct_items,
    CASE
        WHEN ia.total_qty > (SELECT max_qty FROM max_qty) THEN 'Above Max'
        ELSE 'Below Max'
    END AS qty_category,
    RANK() OVER (ORDER BY ia.total_qty DESC) AS qty_rank,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY ia.total_qty DESC) AS rn_state
FROM
    tpcds.warehouse w
    FULL OUTER JOIN inv_agg ia
        ON w.w_warehouse_sk = ia.inv_warehouse_sk
WHERE
    w.w_country = 'United States'
    AND w.w_county IN ('Daviess County', 'Marshall County', 'Wadena County')
    AND (ia.total_qty IS NULL OR ia.total_qty > 200)
    AND w.w_city IS NOT NULL
ORDER BY
    qty_rank
OFFSET 0 FETCH NEXT 100 ROWS ONLY
