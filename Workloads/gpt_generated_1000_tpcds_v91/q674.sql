/*
Goal: Compute total net profit and total return loss for each call center, promotion and year (2020), classify the result as Profit or Loss, include the average income band lower bound, a scalar overall average profit, a correlated count of returns for the same customer on the same day, and rank call centers by profit.
*/
WITH aggregated AS (
    SELECT
        cc.cc_name,
        d_sold.d_year,
        p.p_promo_name,
        c.c_customer_sk,
        d_sold.d_date_sk,
        SUM(cs.cs_net_profit) AS cs_total_net_profit,
        SUM(ws.ws_net_profit) AS ws_total_net_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS cr_total_net_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS wr_total_net_loss,
        AVG(ib.ib_lower_bound) AS avg_income_lower_bound
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN date_dim d_cr_return
        ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN date_dim d_wr_return
        ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
    LEFT JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE d_sold.d_year = 2020
    GROUP BY
        cc.cc_name,
        d_sold.d_year,
        p.p_promo_name,
        c.c_customer_sk,
        d_sold.d_date_sk
)
SELECT
    a.cc_name,
    a.d_year,
    a.p_promo_name,
    a.cs_total_net_profit,
    a.ws_total_net_profit,
    a.cs_total_net_profit + a.ws_total_net_profit AS total_net_profit,
    a.cr_total_net_loss + a.wr_total_net_loss AS total_return_loss,
    CASE
        WHEN a.cs_total_net_profit + a.ws_total_net_profit > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_category,
    a.avg_income_lower_bound,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_cs_profit,
    (SELECT COUNT(*)
        FROM web_returns wr2
        WHERE wr2.wr_returning_customer_sk = a.c_customer_sk
          AND wr2.wr_returned_date_sk = a.d_date_sk) AS returns_by_customer_on_day,
    ROW_NUMBER() OVER (PARTITION BY a.cc_name ORDER BY (a.cs_total_net_profit + a.ws_total_net_profit) DESC) AS rn
FROM aggregated a
ORDER BY a.cc_name, a.d_year, a.p_promo_name
LIMIT 100
