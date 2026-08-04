WITH base AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_ticket_number,
        hd.hd_buy_potential,
        r.r_reason_desc,
        ws.ws_sales_price,
        ws.ws_list_price,
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        ws.ws_ship_date_sk,
        wsite.web_name
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE r.r_reason_desc = 'Found a better price in a store'
      AND hd.hd_vehicle_count > 1
      AND ws.ws_list_price > 50
      AND ws.ws_ship_date_sk = 2451411
      AND wp.wp_autogen_flag = 'N'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
            AND ws2.ws_list_price > 100
      )
),
agg AS (
    SELECT
        base.r_reason_desc,
        base.hd_buy_potential,
        base.web_name,
        SUM(base.sr_return_amt) AS total_return_amt,
        AVG(base.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT base.ws_order_number) AS distinct_orders,
        MAX(base.ws_list_price) AS max_list_price,
        MIN(base.ws_list_price) AS min_list_price
    FROM base
    GROUP BY
        base.r_reason_desc,
        base.hd_buy_potential,
        base.web_name
)
SELECT
    agg.r_reason_desc,
    agg.hd_buy_potential,
    agg.web_name,
    agg.total_return_amt,
    agg.avg_sales_price,
    agg.distinct_orders,
    agg.max_list_price,
    agg.min_list_price,
    ROW_NUMBER() OVER (PARTITION BY agg.r_reason_desc ORDER BY agg.total_return_amt DESC) AS rn
FROM agg
ORDER BY agg.total_return_amt DESC
LIMIT 100
