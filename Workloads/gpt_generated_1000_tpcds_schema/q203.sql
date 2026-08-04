WITH avg_profit AS (
    SELECT avg(cs_net_profit) AS avg_profit
    FROM catalog_sales
)
SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    sold.d_date AS sold_date,
    cs.cs_ship_date_sk,
    ship.d_date AS ship_date,
    td.t_time AS sold_time,
    sm.sm_ship_mode_id,
    sm.sm_code,
    sm.sm_carrier,
    pr.p_promo_name,
    cs.cs_quantity,
    cs.cs_net_profit,
    CASE WHEN cs.cs_net_profit > (SELECT avg_profit FROM avg_profit) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category,
    RANK() OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY cs.cs_net_profit DESC) AS profit_rank_by_ship_mode
FROM catalog_sales cs
JOIN date_dim sold
  ON cs.cs_sold_date_sk = sold.d_date_sk
JOIN date_dim ship
  ON cs.cs_ship_date_sk = ship.d_date_sk
JOIN time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion pr
  ON cs.cs_promo_sk = pr.p_promo_sk
WHERE sold.d_fy_week_seq IN (4, 5, 11)
  AND sold.d_weekend = 'N'
  AND sm.sm_code = 'AIR'
  AND sm.sm_carrier = 'AIRBORNE'
  AND td.t_am_pm = 'PM'
  AND cs.cs_quantity > 2
  AND cs.cs_wholesale_cost < 80
  AND EXISTS (
        SELECT 1 FROM time_dim t2
        WHERE t2.t_time_sk = cs.cs_sold_time_sk
          AND t2.t_minute IN (5, 13, 19)
          AND t2.t_am_pm = 'PM'
      )
ORDER BY profit_rank_by_ship_mode ASC, cs.cs_net_profit DESC
LIMIT 100
