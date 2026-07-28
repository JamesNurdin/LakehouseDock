WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        d.d_year,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(sr.sr_net_loss) AS return_loss,
        SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) AS total_profit
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
            AND cs.cs_item_sk = i.i_item_sk
            AND cs.cs_bill_customer_sk = c.c_customer_sk
            AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
            AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_item_sk = i.i_item_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
            AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        d.d_year = 2001
        AND i.i_brand = 'Brand#12'
        AND cd.cd_gender = 'M'
        AND hd.hd_vehicle_count >= 2
        AND sm.sm_type = 'AIR'
        AND cc.cc_division = 3
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        d.d_year
    HAVING
        (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss)) > 10000
)
SELECT
    DISTINCT b.i_item_id,
    b.i_brand,
    b.d_year,
    b.total_profit,
    CASE
        WHEN b.total_profit > 20000 THEN 'High'
        WHEN b.total_profit > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_tier,
    (SELECT avg(i2.i_current_price) FROM item i2 WHERE i2.i_brand = b.i_brand) AS avg_brand_price,
    ROW_NUMBER() OVER (PARTITION BY b.i_brand ORDER BY b.total_profit DESC) AS brand_rank
FROM base b
ORDER BY b.total_profit DESC
LIMIT 100
