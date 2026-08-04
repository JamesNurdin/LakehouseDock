WITH agg_returns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT
    cs.cs_order_number,
    d_sold.d_year,
    i_sales.i_brand,
    w.w_warehouse_name,
    cp.cp_catalog_number,
    p.p_promo_name,
    r.r_reason_desc,
    s.s_store_name,
    flags.flag,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    COALESCE(ar.total_return_amt, 0) AS total_return_amt_from_cte,
    (
        SELECT SUM(wr3.wr_return_amt)
        FROM web_returns wr3
        WHERE wr3.wr_item_sk = i_sales.i_item_sk
    ) AS item_return_amt_scalar
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_page_start ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end ON cp.cp_end_date_sk = d_page_end.d_date_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i_sales ON cs.cs_item_sk = i_sales.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN agg_returns ar ON i_sales.i_item_sk = ar.wr_item_sk
JOIN web_returns wr ON wr.wr_item_sk = i_sales.i_item_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
CROSS JOIN (SELECT 'A' AS flag UNION ALL SELECT 'B' AS flag) AS flags
WHERE i_sales.i_class_id IN (
        SELECT i_class_id FROM item WHERE i_class_id = 6
        EXCEPT
        SELECT i_class_id FROM item WHERE i_class_id = 8
    )
  AND i_sales.i_class_id IN (
        SELECT i_class_id FROM item WHERE i_class_id = 4
        INTERSECT
        SELECT i_class_id FROM item WHERE i_class_id = 4
    )
  AND i_sales.i_item_sk IN (
        SELECT cs2.cs_item_sk FROM catalog_sales cs2 WHERE cs2.cs_quantity > 0
    )
GROUP BY
    cs.cs_order_number,
    d_sold.d_year,
    i_sales.i_brand,
    w.w_warehouse_name,
    cp.cp_catalog_number,
    p.p_promo_name,
    r.r_reason_desc,
    s.s_store_name,
    flags.flag,
    ar.total_return_amt,
    i_sales.i_item_sk
ORDER BY total_net_paid DESC
LIMIT 100
