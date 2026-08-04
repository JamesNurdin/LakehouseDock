WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d_sold.d_year = 2001
      AND i.i_brand = 'ableanti'
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
)
SELECT
    cc.cc_name,
    w.w_warehouse_name,
    i.i_item_id,
    cp.cp_department,
    s.s_store_name,
    ws.web_name,
    SUM(b.cs_quantity)                                    AS total_quantity,
    SUM(b.cs_net_paid)                                    AS total_net_paid,
    AVG(b.cs_net_profit)                                  AS avg_net_profit,
    CASE
        WHEN SUM(b.cs_net_profit) > 10000 THEN 'HIGH'
        ELSE 'LOW'
    END                                                   AS profit_category,
    RANK() OVER (PARTITION BY cc.cc_name ORDER BY SUM(b.cs_net_paid) DESC) AS sales_rank,
    (
        SELECT AVG(cs_net_paid)
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_item_sk = i.i_item_sk
    )                                                    AS avg_item_net_paid,
    inv_sum.total_on_hand,
    ret_stats.total_return_amount,
    COUNT(DISTINCT cr.cr_return_quantity)                 AS return_count,
    MAX(wr.wr_return_amt)                                 AS max_web_return_amt
FROM base b
JOIN call_center cc ON b.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON b.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON b.cs_item_sk = i.i_item_sk
JOIN catalog_page cp ON b.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON b.cs_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
    ON b.cs_order_number = cr.cr_order_number
   AND cr.cr_item_sk = i.i_item_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN LATERAL (
    SELECT SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
) inv_sum ON TRUE
LEFT JOIN LATERAL (
    SELECT SUM(wr2.wr_return_amt) AS total_return_amount
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = i.i_item_sk
) ret_stats ON TRUE
LEFT JOIN store s
    ON s.s_closed_date_sk = b.cs_sold_date_sk
LEFT JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = b.cs_sold_date_sk
LEFT JOIN date_dim d_site
    ON ws.web_open_date_sk = d_site.d_date_sk
WHERE r.r_reason_desc = 'Customer not satisfied'
  AND s.s_state = 'CA'
  AND ws.web_city = 'New York'
GROUP BY
    cc.cc_name,
    w.w_warehouse_name,
    i.i_item_id,
    cp.cp_department,
    s.s_store_name,
    ws.web_name,
    i.i_item_sk,
    inv_sum.total_on_hand,
    ret_stats.total_return_amount
HAVING SUM(b.cs_quantity) > 100
ORDER BY total_net_paid DESC
OFFSET 0 LIMIT 100
