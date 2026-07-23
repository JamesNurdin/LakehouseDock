WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        sm.sm_carrier,
        t.t_hour,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(sr.sr_net_loss) AS store_return_loss,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(wr.wr_net_loss) AS web_return_loss,
        (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS avg_promo_cost
    FROM
        time_dim t
        JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN item i ON i.i_item_sk = ss.ss_item_sk
        JOIN promotion p ON p.p_promo_sk = ss.ss_promo_sk
        JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN customer_address ca ON ca.ca_address_sk = cr.cr_refunded_addr_sk
        JOIN customer_demographics cd ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
        JOIN household_demographics hd ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
        JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        i.i_current_price > 100
        AND cd.cd_gender = 'M'
        AND hd.hd_vehicle_count >= 2
        AND ib.ib_upper_bound >= 50000
        AND sm.sm_carrier = 'UPS'
        AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        sm.sm_carrier,
        t.t_hour
)
SELECT
    b.i_category,
    b.i_brand,
    SUM(b.store_net_profit + b.web_net_profit - b.store_return_loss - b.catalog_return_loss - b.web_return_loss) AS net_profit,
    AVG(b.avg_promo_cost) AS avg_promo_cost_per_category,
    COUNT(DISTINCT b.i_item_sk) AS distinct_items
FROM
    base b
WHERE
    EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = b.i_item_sk
          AND p2.p_cost > 500
    )
GROUP BY
    b.i_category,
    b.i_brand
HAVING
    SUM(b.store_net_profit + b.web_net_profit - b.store_return_loss - b.catalog_return_loss - b.web_return_loss) > 10000
ORDER BY
    net_profit DESC
LIMIT 100
