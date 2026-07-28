WITH filtered_time AS (
    SELECT t_time_sk, t_hour, t_minute
    FROM time_dim
    WHERE t_hour IN (10, 14)
      AND t_minute IN (2, 7)
)
SELECT
    s.s_store_name,
    sm.sm_type,
    w.w_warehouse_name,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_net_loss ELSE 0 END) AS total_return_loss,
    AVG(cs.cs_quantity) AS avg_quantity_sold,
    MIN(cs.cs_sold_date_sk) AS first_sale_date_sk,
    MAX(cs.cs_sold_date_sk) AS last_sale_date_sk
FROM filtered_time ft
JOIN catalog_sales cs
    ON cs.cs_sold_time_sk = ft.t_time_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory i
    ON w.w_warehouse_sk = i.inv_warehouse_sk
JOIN store_returns sr
    ON sr.sr_return_time_sk = ft.t_time_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE sm.sm_type = 'EXPRESS'
  AND r.r_reason_id = 'AAAAAAAALAAAAAAA'
  AND s.s_state = 'CA'
  AND cs.cs_quantity > 5
  AND (i.inv_quantity_on_hand IS NULL OR i.inv_quantity_on_hand >= 100)
GROUP BY
    s.s_store_name,
    sm.sm_type,
    w.w_warehouse_name
ORDER BY total_net_profit DESC
LIMIT 100
