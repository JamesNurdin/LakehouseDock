/*
Goal: Identify high‑value catalog orders, enrich them with shipping mode, time‑of‑day, and website information, compute running totals and previous‑order values per shipping mode, and exclude orders that also appear as low‑value web sales.
*/
WITH cs_agg AS (
    SELECT
        cs_order_number,
        SUM(cs_net_paid) AS cs_total_paid,
        SUM(cs_ext_discount_amt) AS cs_total_discount,
        MIN(cs_sold_time_sk) AS cs_min_time_sk
    FROM catalog_sales
    WHERE cs_net_paid > 1000
      AND cs_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_contract LIKE 'A%')
    GROUP BY cs_order_number
),
ws_agg AS (
    SELECT
        ws_order_number,
        SUM(ws_net_paid) AS ws_total_paid,
        SUM(ws_ext_discount_amt) AS ws_total_discount,
        MAX(ws_sold_time_sk) AS ws_max_time_sk
    FROM web_sales
    WHERE ws_net_paid_inc_tax > 1500
    GROUP BY ws_order_number
)
SELECT
    ca.cs_order_number,
    ca.cs_total_paid,
    wa.ws_total_paid,
    sm.sm_ship_mode_id,
    ws.ws_ship_mode_sk,
    ws.ws_sold_time_sk,
    td.t_hour,
    ws_site.web_state,
    LAG(ca.cs_total_paid) OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY td.t_hour) AS lag_cs_total_paid,
    SUM(ca.cs_total_paid) OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY td.t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_cs_total_paid
FROM cs_agg ca
JOIN catalog_sales cs
    ON cs.cs_order_number = ca.cs_order_number
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN web_sales ws
    ON ws.ws_order_number = ca.cs_order_number
   AND ws.ws_sold_time_sk = td.t_time_sk
JOIN ws_agg wa
    ON wa.ws_order_number = ws.ws_order_number
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_returned_time_sk = td.t_time_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND ws_site.web_state = 'MI'
  AND sm.sm_type = 'AIR'
  AND ca.cs_order_number NOT IN (
        SELECT ws_inner.ws_order_number
        FROM web_sales ws_inner
        WHERE ws_inner.ws_net_paid < 500
    )
ORDER BY ca.cs_total_paid DESC, td.t_hour
LIMIT 100
