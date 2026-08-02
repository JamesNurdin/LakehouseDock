WITH
    store_ret AS (
        SELECT 
            i.i_item_sk,
            i.i_item_id,
            i.i_product_name,
            SUM(sr.sr_return_quantity) AS total_qty,
            SUM(sr.sr_return_amt) AS total_amt,
            'store' AS source
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE s.s_state = 'TX'
          AND i.i_brand_id IN (1002001, 6008007)
          AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
        GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
    ),
    web_ret AS (
        SELECT 
            i.i_item_sk,
            i.i_item_id,
            i.i_product_name,
            SUM(wr.wr_return_quantity) AS total_qty,
            SUM(wr.wr_return_amt) AS total_amt,
            'web' AS source
        FROM web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE i.i_category = 'Electronics'
          AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
        GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
    ),
    combined AS (
        SELECT i_item_sk, i_item_id, i_product_name, total_qty, total_amt, source FROM store_ret
        UNION ALL
        SELECT i_item_sk, i_item_id, i_product_name, total_qty, total_amt, source FROM web_ret
    ),
    filtered AS (
        SELECT 
            c.i_item_sk,
            c.i_item_id,
            c.i_product_name,
            SUM(c.total_qty) AS agg_qty,
            SUM(c.total_amt) AS agg_amt,
            COUNT(*) FILTER (WHERE c.source = 'store') AS store_cnt,
            COUNT(*) FILTER (WHERE c.source = 'web') AS web_cnt
        FROM combined c
        GROUP BY c.i_item_sk, c.i_item_id, c.i_product_name
        HAVING SUM(c.total_amt) > (
            SELECT AVG(sr2.sr_return_amt)
            FROM store_returns sr2
        )
    )
SELECT 
    f.i_item_id,
    f.i_product_name,
    f.agg_qty,
    f.agg_amt,
    f.store_cnt,
    f.web_cnt
FROM filtered f
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory inv
    WHERE inv.inv_item_sk = f.i_item_sk
      AND inv.inv_quantity_on_hand > 0
      AND inv.inv_date_sk = 2450050
)
ORDER BY f.agg_amt DESC
OFFSET 0 LIMIT 100
