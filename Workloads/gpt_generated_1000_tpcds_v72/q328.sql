WITH sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        t.t_hour,
        SUM(cs.cs_net_profit)                              AS catalog_profit,
        SUM(ss.ss_net_profit)                              AS store_profit,
        SUM(ws.ws_net_profit)                              AS web_profit,
        SUM(sr.sr_net_loss)                                AS store_return_loss,
        SUM(wr.wr_net_loss)                                AS web_return_loss,
        SUM(inv.inv_quantity_on_hand)                      AS total_on_hand,
        COUNT(DISTINCT cs.cs_order_number)                 AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number)                AS store_orders,
        COUNT(DISTINCT ws.ws_order_number)                 AS web_orders
    FROM catalog_sales cs
    JOIN time_dim t          ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN warehouse w         ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN store_sales ss      ON ss.ss_sold_time_sk   = t.t_time_sk
    JOIN web_sales ws        ON ws.ws_sold_time_sk   = t.t_time_sk
    JOIN store_returns sr    ON sr.sr_ticket_number  = ss.ss_ticket_number
                               AND sr.sr_return_time_sk = t.t_time_sk
    JOIN web_returns wr      ON wr.wr_order_number   = ws.ws_order_number
                               AND wr.wr_returned_time_sk = t.t_time_sk
    JOIN inventory inv       ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib          ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        ib.ib_upper_bound > 100000                     /* high‑income band */
        AND cd.cd_credit_rating = 'Good'               /* good credit customers */
        AND hd.hd_vehicle_count >= 2                   /* at least two vehicles */
        AND t.t_hour BETWEEN 9 AND 17                  /* business hours */
        AND inv.inv_quantity_on_hand > 0               /* has stock */
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id, t.t_hour
    HAVING (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) > 10000
)
SELECT
    sa.w_warehouse_id,
    sa.t_hour,
    sa.catalog_profit,
    sa.store_profit,
    sa.web_profit,
    sa.store_return_loss,
    sa.web_return_loss,
    sa.total_on_hand,
    (sa.catalog_profit + sa.store_profit + sa.web_profit)                         AS total_sales_profit,
    (sa.store_return_loss + sa.web_return_loss)                                    AS total_return_loss,
    ((sa.catalog_profit + sa.store_profit + sa.web_profit) -
     (sa.store_return_loss + sa.web_return_loss))                                 AS net_profit_after_returns,
    ROW_NUMBER() OVER (PARTITION BY sa.t_hour
                       ORDER BY ((sa.catalog_profit + sa.store_profit + sa.web_profit) -
                                 (sa.store_return_loss + sa.web_return_loss)) DESC) AS rn
FROM sales_agg sa
WHERE EXISTS (
    SELECT 1
    FROM inventory inv2
    WHERE inv2.inv_warehouse_sk = sa.w_warehouse_sk
      AND inv2.inv_quantity_on_hand > 500
)
ORDER BY net_profit_after_returns DESC, rn
LIMIT 100
