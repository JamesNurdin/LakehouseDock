WITH base AS (
    SELECT
        cp.cp_catalog_page_id,
        d_start.d_date,
        s.s_store_name,
        i.i_product_name,
        inv.inv_quantity_on_hand,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        CASE 
            WHEN wr.wr_return_amt > 100 THEN 'high'
            WHEN wr.wr_return_amt BETWEEN 50 AND 100 THEN 'medium'
            ELSE 'low'
        END AS return_category,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY wr.wr_return_amt DESC) AS rn
    FROM catalog_page cp
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_start.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_start.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_start.d_date_sk
    JOIN item i
        ON i.i_item_sk = inv.inv_item_sk
        AND i.i_item_sk = wr.wr_item_sk
    WHERE d_start.d_year = 2001
      AND s.s_state = 'TX'
      AND i.i_class = 'sports-apparel'
)
SELECT
    cp_catalog_page_id,
    d_date,
    s_store_name,
    i_product_name,
    inv_quantity_on_hand,
    wr_return_quantity,
    wr_return_amt,
    return_category,
    rn,
    SUM(wr_return_amt) OVER (
        PARTITION BY s_store_name
        ORDER BY d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amt
FROM base
WHERE rn <= 3
ORDER BY s_store_name, rn
