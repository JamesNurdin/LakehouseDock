WITH joined_data AS (
    SELECT
        s.s_store_id,
        d.d_year,
        ws.ws_net_profit AS sales_profit,
        sr.sr_net_loss AS return_loss,
        ws.ws_quantity,
        sr.sr_return_quantity
    FROM tpcds.date_dim d
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON s.s_store_sk = sr.sr_store_sk
    JOIN tpcds.reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = sr.sr_cdemo_sk
    JOIN tpcds.household_demographics hd
        ON hd.hd_demo_sk = sr.sr_hdemo_sk
    JOIN tpcds.income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN tpcds.promotion p
        ON p.p_start_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    JOIN tpcds.web_site we
        ON we.web_site_sk = ws.ws_web_site_sk
    JOIN tpcds.web_page wp
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE
        d.d_year = 2001
        AND we.web_class = 'Unknown'
        AND ib.ib_upper_bound >= 90000
        AND p.p_discount_active = 'Y'
        AND i.inv_quantity_on_hand > 0
        AND r.r_reason_desc LIKE '%damage%'
)
SELECT
    s_store_id,
    d_year,
    SUM(sales_profit) AS total_sales_profit,
    SUM(return_loss) AS total_return_loss,
    (SUM(sales_profit) - SUM(return_loss)) AS net_profit,
    COUNT(*) AS txn_count
FROM joined_data
GROUP BY s_store_id, d_year
HAVING SUM(sales_profit) > 10000
ORDER BY net_profit DESC
LIMIT 10
