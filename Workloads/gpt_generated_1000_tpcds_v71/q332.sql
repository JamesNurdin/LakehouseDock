/*
Goal: Compute per‑item sales performance across catalog and web channels, combine with store, catalog and web return amounts, inventory on hand and promotion cost information, rank items within each category by total sales, and return the top 100 rows after applying realistic filters.
*/
WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_color,
        i.i_category,
        SUM(cs.cs_ext_sales_price)                         AS total_catalog_sales,
        SUM(ws.ws_ext_sales_price)                         AS total_web_sales,
        AVG(cs.cs_ext_discount_amt)                        AS avg_catalog_discount,
        COUNT(DISTINCT cs.cs_bill_customer_sk)             AS distinct_customers,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM item i
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    LEFT JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN customer cu_ws ON ws.ws_bill_customer_sk = cu_ws.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100                      -- filter on sold date key
      AND i.i_color IN ('tan', 'royal')                                      -- filter on item colour
      AND (p_cs.p_discount_active = 'Y' OR p_cs.p_discount_active IS NULL)   -- only active promotions (or none)
    GROUP BY i.i_item_sk, i.i_item_id, i.i_color, i.i_category
)
SELECT
    sa.i_item_id,
    sa.i_color,
    sa.total_catalog_sales,
    sa.total_web_sales,
    sa.avg_catalog_discount,
    sa.distinct_customers,
    sa.sales_rank,
    COALESCE(sr.total_return_amount, 0)  AS total_store_return,
    COALESCE(cr.total_return_amount, 0)  AS total_catalog_return,
    COALESCE(wr.total_return_amount, 0)  AS total_web_return,
    inv.inv_quantity_on_hand,
    (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_item_sk = sa.i_item_sk
    )                                     AS max_promo_cost
FROM sales_agg sa
JOIN inventory inv ON inv.inv_item_sk = sa.i_item_sk
LEFT JOIN (
    SELECT sr_item_sk, SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2450000 AND 2450100          -- filter on return date key
      AND sr_return_quantity > 0
    GROUP BY sr_item_sk
) sr ON sr.sr_item_sk = sa.i_item_sk
LEFT JOIN (
    SELECT cr_item_sk, SUM(cr_return_amt_inc_tax) AS total_return_amount
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450000 AND 2450100          -- filter on return date key
      AND cr_return_quantity > 0
      AND cr_ship_mode_sk IN (3, 9)                                 -- filter on ship mode
    GROUP BY cr_item_sk
) cr ON cr.cr_item_sk = sa.i_item_sk
LEFT JOIN (
    SELECT wr_item_sk, SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2450000 AND 2450100          -- filter on return date key
      AND wr_return_quantity > 0
    GROUP BY wr_item_sk
) wr ON wr.wr_item_sk = sa.i_item_sk
WHERE inv.inv_quantity_on_hand > 500                                 -- filter on inventory level
ORDER BY sa.total_catalog_sales + sa.total_web_sales DESC
LIMIT 100
