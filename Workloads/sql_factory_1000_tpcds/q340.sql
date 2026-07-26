SELECT
    ss.ss_store_sk,
    i.i_brand,
    SUM(ss.ss_quantity) AS total_sold_qty,
    COALESCE(SUM(wr.wr_return_quantity), 0) AS total_return_qty,
    CASE
        WHEN COALESCE(SUM(wr.wr_return_quantity), 0) = 0 THEN NULL
        ELSE (SUM(ss.ss_quantity) - SUM(wr.wr_return_quantity)) / CAST(SUM(ss.ss_quantity) AS DOUBLE)
    END AS sell_through_rate,
    RANK() OVER (PARTITION BY ss.ss_store_sk ORDER BY (SUM(ss.ss_quantity) - COALESCE(SUM(wr.wr_return_quantity), 0)) DESC) AS brand_sales_rank_in_store,
    DENSE_RANK() OVER (ORDER BY (SUM(ss.ss_quantity) - COALESCE(SUM(wr.wr_return_quantity), 0)) DESC) AS overall_brand_sales_rank
FROM store_sales ss
JOIN item i ON i.i_item_sk = ss.ss_item_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = ss.ss_item_sk
GROUP BY ss.ss_store_sk, i.i_brand
HAVING SUM(ss.ss_quantity) > 0
ORDER BY ss.ss_store_sk, brand_sales_rank_in_store
LIMIT 20
