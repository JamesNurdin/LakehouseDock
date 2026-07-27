WITH cs AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_warehouse_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2020
      AND i.i_category_id IN (2, 4, 7)
      AND p.p_channel_email = 'N'
      AND i.i_formulation LIKE '%thistle%'
      AND w.w_state = 'CA'
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    i.i_category,
    d.d_year,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_returns,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_returns,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    MAX(p.p_discount_active) AS max_discount_active
FROM cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = cs.cs_item_sk
   AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = cs.cs_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = cs.cs_item_sk
   AND inv.inv_date_sk = d.d_date_sk
LEFT JOIN store_sales ss
    ON ss.ss_item_sk = cs.cs_item_sk
   AND ss.ss_sold_date_sk = d.d_date_sk
   AND ss.ss_sold_time_sk = cs.cs_sold_time_sk
   AND ss.ss_promo_sk = cs.cs_promo_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = cs.cs_item_sk
   AND ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_sold_time_sk = cs.cs_sold_time_sk
   AND ws.ws_promo_sk = cs.cs_promo_sk
WHERE EXISTS (
    SELECT 1
    FROM reason r
    WHERE r.r_reason_desc LIKE '%defect%'
      AND r.r_reason_sk = sr.sr_reason_sk
)
GROUP BY i.i_category, d.d_year
ORDER BY total_sales DESC
LIMIT 100
