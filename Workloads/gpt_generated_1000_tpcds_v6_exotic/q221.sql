WITH agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        w.web_name,
        sm.sm_code,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(*) AS return_cnt
    FROM web_sales ws
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    WHERE w.web_rec_end_date > DATE '2000-01-01'
      AND sm.sm_code IN ('AIR', 'SEA')
      AND wr.wr_return_amt_inc_tax > 500
      AND EXISTS (
            SELECT 1
            FROM reason r
            WHERE r.r_reason_sk = wr.wr_reason_sk
              AND r.r_reason_desc LIKE '%damaged%'
      )
    GROUP BY ws.ws_order_number, ws.ws_sold_date_sk, w.web_name, sm.sm_code
    HAVING COUNT(*) >= 2
)
SELECT
    agg.ws_order_number,
    agg.ws_sold_date_sk,
    agg.web_name,
    agg.sm_code,
    agg.total_return_inc_tax,
    agg.return_cnt,
    RANK() OVER (ORDER BY agg.total_return_inc_tax DESC) AS site_return_rank,
    CASE WHEN agg.total_return_inc_tax > 2000 THEN 'HIGH' ELSE 'NORMAL' END AS return_level
FROM agg
ORDER BY agg.total_return_inc_tax DESC
LIMIT 100
