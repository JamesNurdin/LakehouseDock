WITH per_store_hour AS (
    SELECT
        s.s_store_id AS store_id,
        t.t_hour AS hour,
        SUM(sr.sr_net_loss) AS store_return_net_loss,
        SUM(cr.cr_net_loss) AS catalog_return_net_loss,
        SUM(wr.wr_net_loss) AS web_return_net_loss,
        SUM(cs.cs_net_profit) AS catalog_sales_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        CASE WHEN ib.ib_upper_bound > 100000 THEN 'High Income' ELSE 'Low Income' END AS income_category
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN income_band ib
        ON hd_sr.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_refunded_hdemo_sk = hd_sr.hd_demo_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_refunded_hdemo_sk = hd_sr.hd_demo_sk
    WHERE
        t.t_hour BETWEEN 9 AND 17
        AND s.s_number_employees > 250
        AND ib.ib_upper_bound >= 70000
        AND cc.cc_state = 'CA'
        AND w.w_state = 'CA'
        AND sr.sr_return_quantity > 0
        AND cs.cs_quantity > 0
        AND EXISTS (
            SELECT 1
            FROM inventory i
            WHERE i.inv_warehouse_sk = w.w_warehouse_sk
              AND i.inv_quantity_on_hand > 100
        )
    GROUP BY
        s.s_store_id,
        t.t_hour,
        ib.ib_upper_bound,
        CASE WHEN ib.ib_upper_bound > 100000 THEN 'High Income' ELSE 'Low Income' END
)
SELECT
    store_id,
    hour,
    income_category,
    store_return_net_loss,
    catalog_return_net_loss,
    web_return_net_loss,
    catalog_sales_net_profit,
    distinct_orders,
    (store_return_net_loss + catalog_return_net_loss + web_return_net_loss) AS total_return_net_loss,
    (catalog_sales_net_profit - (store_return_net_loss + catalog_return_net_loss + web_return_net_loss)) AS net_profit_after_returns,
    ROUND((catalog_sales_net_profit - (store_return_net_loss + catalog_return_net_loss + web_return_net_loss)) / NULLIF(distinct_orders, 0), 2) AS avg_profit_per_order
FROM per_store_hour
WHERE (store_return_net_loss + catalog_return_net_loss + web_return_net_loss) > 0
ORDER BY net_profit_after_returns DESC
