/*
Goal: Identify, for each store and hour of day, the total profit and sales from in‑store transactions that meet several business criteria, and only keep those store‑hour combos with substantial profit. The query joins all seven TPC‑DS tables, uses a CTE for the base sales filter, an EXISTS semi‑join to web_sales, and a second CTE to aggregate per store‑hour.
*/
WITH base_sales AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_id,
        td.t_hour,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ca.ca_gmt_offset,
        i.i_current_price,
        p.p_discount_active,
        ss.ss_addr_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_gmt_offset = -5.00                                -- predicate 1
      AND i.i_current_price > 20                                  -- predicate 2
      AND p.p_discount_active = 'Y'                               -- predicate 3
      AND td.t_hour BETWEEN 8 AND 20                              -- predicate 4
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
          WHERE ws.ws_item_sk = ss.ss_item_sk
            AND ws.ws_promo_sk = ss.ss_promo_sk
            AND ws.ws_bill_addr_sk = ss.ss_addr_sk
            AND ws.ws_net_paid_inc_tax > 500                     -- predicate 5 (inside subquery)
            AND td_ws.t_meal_time = 'Dinner'                     -- predicate 6 (inside subquery)
      )
),
store_hour_agg AS (
    SELECT
        s_store_id,
        t_hour,
        SUM(ss_net_profit) AS profit_sum,
        SUM(ss_ext_sales_price) AS sales_sum,
        COUNT(*) AS txn_cnt
    FROM base_sales
    GROUP BY s_store_id, t_hour
)
SELECT
    s_store_id,
    t_hour,
    profit_sum,
    sales_sum,
    txn_cnt,
    profit_sum / NULLIF(txn_cnt, 0) AS avg_profit_per_txn
FROM store_hour_agg
WHERE profit_sum > 1000
ORDER BY profit_sum DESC
LIMIT 100
