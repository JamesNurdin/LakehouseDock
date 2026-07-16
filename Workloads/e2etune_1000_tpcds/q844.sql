WITH ss_agg AS (
    SELECT
        td.t_hour AS hour_of_day,
        p.p_channel_email AS promo_email_channel,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND p.p_channel_email = 'Y'
    GROUP BY td.t_hour, p.p_channel_email
),
cr_agg AS (
    SELECT
        td.t_hour AS hour_of_day,
        w.w_warehouse_id AS warehouse_id,
        w.w_city AS city,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY td.t_hour, w.w_warehouse_id, w.w_city
),
inv_agg AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id
)
SELECT
    ss.hour_of_day,
    ss.promo_email_channel,
    ss.total_sales_profit,
    ss.sales_cnt,
    cr.warehouse_id,
    cr.city,
    cr.total_return_loss,
    cr.returns_cnt,
    inv.total_inventory_qty,
    (ss.total_sales_profit - cr.total_return_loss) AS net_profit_loss
FROM ss_agg ss
FULL OUTER JOIN cr_agg cr
    ON ss.hour_of_day = cr.hour_of_day
FULL OUTER JOIN inv_agg inv
    ON cr.warehouse_id = inv.warehouse_id
ORDER BY ss.hour_of_day NULLS LAST, cr.total_return_loss DESC
LIMIT 100
