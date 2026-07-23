WITH monthly_sales AS (
    SELECT
        i.i_category AS category,
        dd_sold.d_year AS year,
        dd_sold.d_moy AS month,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss
    FROM web_sales ws
    JOIN date_dim dd_sold
        ON ws.ws_sold_date_sk = dd_sold.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN date_dim dd_wr
        ON wr.wr_returned_date_sk = dd_wr.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_returned_date_sk = dd_sold.d_date_sk
    LEFT JOIN date_dim dd_sr
        ON sr.sr_returned_date_sk = dd_sr.d_date_sk
    WHERE dd_sold.d_year = 2001
      AND dd_sold.d_moy IN (1, 4, 6)
      AND i.i_current_price > 20
      AND sm.sm_type = 'OVERNIGHT'
      AND sm.sm_contract = 'Ek'
      AND wh.w_warehouse_sq_ft > 10000
      AND hd.hd_vehicle_count >= 2
      AND dd_sold.d_weekend = 'N'
      AND dd_sold.d_current_quarter = 'Y'
    GROUP BY i.i_category, dd_sold.d_year, dd_sold.d_moy
)
SELECT
    category,
    AVG(total_sales_profit - (total_web_return_loss + total_store_return_loss)) AS avg_monthly_net_profit
FROM monthly_sales
GROUP BY category
HAVING AVG(total_sales_profit - (total_web_return_loss + total_store_return_loss)) > 1000
ORDER BY avg_monthly_net_profit DESC
LIMIT 100
