WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_net_paid,
        hs.hd_buy_potential,
        hs.hd_vehicle_count,
        wh.w_state,
        ws_site.web_name
    FROM web_sales ws
    JOIN household_demographics hs ON ws.ws_bill_hdemo_sk = hs.hd_demo_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws_site.web_name LIKE '%Shop%'
      AND regexp_like(hs.hd_buy_potential, '^\\d+-\\d+$')
      AND wh.w_street_name LIKE 'Lincoln%'
),
other_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_net_paid,
        hs.hd_buy_potential,
        hs.hd_vehicle_count,
        wh.w_state,
        ws_site.web_name
    FROM web_sales ws
    JOIN household_demographics hs ON ws.ws_bill_hdemo_sk = hs.hd_demo_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws_site.web_name LIKE '%Online%'
),
union_sales AS (
    SELECT * FROM filtered_sales
    UNION ALL
    SELECT * FROM other_sales
),
ranked_sales AS (
    SELECT
        us.*,
        ROW_NUMBER() OVER (PARTITION BY us.ws_web_site_sk ORDER BY us.ws_net_profit DESC) AS rn,
        CAST(regexp_extract(us.hd_buy_potential, '(\\d+)-(\\d+)', 1) AS INTEGER) AS buy_low,
        CAST(regexp_extract(us.hd_buy_potential, '(\\d+)-(\\d+)', 2) AS INTEGER) AS buy_high,
        CONCAT(us.web_name, ' - ', us.w_state) AS site_state
    FROM union_sales us
)
SELECT DISTINCT
    rs.ws_order_number,
    rs.ws_web_site_sk,
    rs.web_name,
    rs.w_state,
    rs.ws_net_profit,
    rs.buy_low,
    rs.buy_high,
    rs.rn,
    SUM(rs.ws_net_profit) OVER (PARTITION BY rs.ws_web_site_sk) AS total_site_profit,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS avg_net_profit_all
FROM ranked_sales rs
WHERE rs.rn <= 3
  AND NOT EXISTS (
      SELECT 1
      FROM web_sales ws2
      JOIN warehouse wh2 ON ws2.ws_warehouse_sk = wh2.w_warehouse_sk
      WHERE ws2.ws_web_site_sk = rs.ws_web_site_sk
        AND wh2.w_city = 'New York'
  )
ORDER BY rs.ws_net_profit DESC
LIMIT 100
