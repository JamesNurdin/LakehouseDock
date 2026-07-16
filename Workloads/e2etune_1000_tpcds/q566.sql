WITH cat_agg AS (
    SELECT w.w_warehouse_name AS warehouse,
           t.t_hour AS hour,
           SUM(cr.cr_net_loss) AS cat_net_loss,
           AVG(cr.cr_return_amt_inc_tax) AS cat_avg_return_inc_tax,
           COUNT(*) AS cat_return_cnt,
           COUNT(DISTINCT cr.cr_item_sk) AS cat_distinct_items,
           COALESCE(SUM(p.p_cost), 0) AS cat_total_promo_cost
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
    WHERE cr.cr_store_credit > 100
      AND t.t_shift = 'Evening'
    GROUP BY w.w_warehouse_name, t.t_hour
),
web_agg AS (
    SELECT t.t_hour AS hour,
           SUM(wr.wr_net_loss) AS web_net_loss,
           AVG(wr.wr_return_amt_inc_tax) AS web_avg_return_inc_tax,
           COUNT(*) AS web_return_cnt,
           COUNT(DISTINCT wr.wr_item_sk) AS web_distinct_items,
           COALESCE(SUM(p.p_cost), 0) AS web_total_promo_cost
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
    WHERE wr.wr_return_ship_cost > 500
      AND t.t_shift = 'Evening'
    GROUP BY t.t_hour
)
SELECT COALESCE(c.warehouse, 'ALL_WAREHOUSES') AS warehouse,
       COALESCE(c.hour, w.hour) AS hour,
       COALESCE(c.cat_net_loss, 0) AS cat_net_loss,
       COALESCE(w.web_net_loss, 0) AS web_net_loss,
       COALESCE(c.cat_avg_return_inc_tax, 0) AS cat_avg_return_inc_tax,
       COALESCE(w.web_avg_return_inc_tax, 0) AS web_avg_return_inc_tax,
       COALESCE(c.cat_return_cnt, 0) AS cat_return_cnt,
       COALESCE(w.web_return_cnt, 0) AS web_return_cnt,
       COALESCE(c.cat_distinct_items, 0) AS cat_distinct_items,
       COALESCE(w.web_distinct_items, 0) AS web_distinct_items,
       COALESCE(c.cat_total_promo_cost, 0) AS cat_total_promo_cost,
       COALESCE(w.web_total_promo_cost, 0) AS web_total_promo_cost,
       (COALESCE(c.cat_net_loss, 0) + COALESCE(w.web_net_loss, 0)) AS total_net_loss
FROM cat_agg c
FULL OUTER JOIN web_agg w ON c.hour = w.hour
ORDER BY total_net_loss DESC
LIMIT 50
