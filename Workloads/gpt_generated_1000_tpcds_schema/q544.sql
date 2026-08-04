WITH
agg_returns AS (
    SELECT
        sr.sr_hdemo_sk AS hdemo_sk,
        sr.sr_return_time_sk AS time_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_refunded_cash) AS avg_refunded_cash,
        COUNT(*) AS cnt_returns
    FROM tpcds.store_returns sr
    JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE hd.hd_income_band_sk IN (3, 16)
      AND sr.sr_return_amt > 10
      AND td.t_hour BETWEEN 9 AND 17
      AND hd.hd_vehicle_count >= 0
    GROUP BY sr.sr_hdemo_sk, sr.sr_return_time_sk
),
agg_sales AS (
    SELECT
        ws.ws_bill_hdemo_sk AS hdemo_sk,
        ws.ws_sold_time_sk AS time_sk,
        ws.ws_web_site_sk AS site_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_quantity) AS avg_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS cnt_orders
    FROM tpcds.web_sales ws
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN tpcds.time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE wsit.web_market_manager = 'David Myers'
      AND sm.sm_code = 'AIR'
      AND wp.wp_url LIKE 'http%://%'
      AND ws.ws_net_paid > 100
      AND td.t_am_pm = 'PM'
    GROUP BY ws.ws_bill_hdemo_sk, ws.ws_sold_time_sk, ws.ws_web_site_sk
),
intersect_sites AS (
    SELECT web_site_sk FROM tpcds.web_site WHERE web_city = 'San Jose'
    INTERSECT
    SELECT ws_web_site_sk FROM tpcds.web_sales WHERE ws_quantity > 5
),
combined AS (
    SELECT
        COALESCE(r.hdemo_sk, s.hdemo_sk) AS demo_sk,
        COALESCE(r.time_sk, s.time_sk) AS time_sk,
        r.total_return_amt,
        s.total_net_paid,
        r.cnt_returns,
        s.cnt_orders,
        (SELECT COUNT(*) FROM tpcds.store_returns sr2 WHERE sr2.sr_hdemo_sk = COALESCE(r.hdemo_sk, s.hdemo_sk)) AS total_returns_per_demo,
        (SELECT MAX(ws_ext_ship_cost) FROM tpcds.web_sales ws2 WHERE ws2.ws_bill_hdemo_sk = COALESCE(r.hdemo_sk, s.hdemo_sk)) AS max_ship_cost,
        s.site_sk
    FROM agg_returns r
    FULL OUTER JOIN agg_sales s
        ON r.time_sk = s.time_sk
    WHERE (r.total_return_amt > 100 OR s.total_net_paid > 1000)
      AND EXISTS (SELECT 1 FROM intersect_sites i WHERE i.web_site_sk = s.site_sk)
)
SELECT demo_sk,
       time_sk,
       total_return_amt,
       total_net_paid,
       cnt_returns,
       cnt_orders,
       total_returns_per_demo,
       max_ship_cost
FROM combined
WHERE demo_sk IS NOT NULL
UNION
SELECT demo_sk,
       time_sk,
       total_return_amt,
       total_net_paid,
       cnt_returns,
       cnt_orders,
       total_returns_per_demo,
       max_ship_cost
FROM combined
WHERE total_net_paid > 5000
ORDER BY total_net_paid DESC
LIMIT 100
