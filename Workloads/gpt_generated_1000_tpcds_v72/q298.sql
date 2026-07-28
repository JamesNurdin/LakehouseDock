WITH avg_discount_per_item AS (
    SELECT ws2.ws_item_sk,
           AVG(ws2.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws2
    GROUP BY ws2.ws_item_sk
)
SELECT
    i.i_category AS item_category,
    ib.ib_income_band_sk AS income_band,
    sm_cs.sm_type AS ship_type,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    CASE WHEN SUM(cs.cs_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0)) > 0
         THEN 'Overall Profit'
         ELSE 'Overall Loss'
    END AS overall_status,
    ad.avg_discount AS avg_web_discount
FROM catalog_sales cs
INNER JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
INNER JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
INNER JOIN ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
INNER JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
INNER JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
INNER JOIN household_demographics hd_ws_bill
        ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN household_demographics hd_wr_refund
        ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
LEFT JOIN avg_discount_per_item ad
        ON ad.ws_item_sk = i.i_item_sk
GROUP BY
    i.i_category,
    ib.ib_income_band_sk,
    sm_cs.sm_type,
    ad.avg_discount
ORDER BY total_catalog_profit DESC
LIMIT 100
