WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_warehouse_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_page_sk,
        ws.ws_bill_hdemo_sk,
        wp.wp_url,
        wp.wp_type,
        sm.sm_ship_mode_id,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_city,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*\\.example\\.com')
      AND wp.wp_type LIKE 'Home%'
      AND EXISTS (
          SELECT 1
          FROM tpcds.income_band ib
          WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
            AND ib.ib_lower_bound >= 150000
      )
)
SELECT
    concat(f.w_warehouse_name, ' (', f.w_city, ')') AS warehouse_location,
    f.sm_ship_mode_id,
    f.domain,
    COUNT(DISTINCT f.ws_order_number) AS orders,
    SUM(f.ws_net_profit) AS total_profit,
    AVG(f.ws_net_profit) AS avg_profit_per_order,
    CASE
        WHEN SUM(f.ws_net_profit) > (SELECT AVG(ws_net_profit) FROM tpcds.web_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM filtered_sales f
GROUP BY
    concat(f.w_warehouse_name, ' (', f.w_city, ')'),
    f.sm_ship_mode_id,
    f.domain
ORDER BY total_profit DESC
