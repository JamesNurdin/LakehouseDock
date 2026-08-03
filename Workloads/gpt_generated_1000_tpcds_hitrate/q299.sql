WITH sales_agg AS (
    SELECT
        s.s_store_id,
        i.i_class,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(wr.wr_net_loss) AS web_return_loss,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(cs.cs_net_profit) DESC) AS rn
    FROM
        catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
           AND cr.cr_item_sk = cs.cs_item_sk
        LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
        LEFT JOIN web_sales ws
            ON ws.ws_order_number = cs.cs_order_number
           AND ws.ws_item_sk = cs.cs_item_sk
        LEFT JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
        LEFT JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
        LEFT JOIN customer c_ws ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
        LEFT JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
        LEFT JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
           AND wr.wr_item_sk = ws.ws_item_sk
        LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
           AND inv.inv_date_sk = d_sold.d_date_sk
        RIGHT JOIN store s
            ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND i.i_class = 'furniture'
        AND s.s_tax_percentage > 0.04
        AND ib.ib_upper_bound <= 50000
    GROUP BY
        s.s_store_id,
        i.i_class
)
SELECT
    s_store_id,
    i_class,
    catalog_orders,
    catalog_net_profit,
    catalog_return_loss,
    web_net_profit,
    web_return_loss,
    profit_flag
FROM
    sales_agg
WHERE
    rn <= 5
ORDER BY
    s_store_id,
    catalog_net_profit DESC
LIMIT 100
