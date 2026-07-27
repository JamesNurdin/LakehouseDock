WITH sales_agg AS (
    SELECT
        cs_order_number,
        SUM(cs_net_paid) AS sum_cs_net_paid,
        AVG(cs_ext_tax) AS avg_cs_ext_tax,
        COUNT(*) AS cnt_cs
    FROM catalog_sales
    WHERE cs_ext_tax > 20.00
      AND cs_quantity >= 2
      AND cs_ship_hdemo_sk = 5128
    GROUP BY cs_order_number
)
SELECT
    td.t_hour,
    c.c_last_name,
    r.r_reason_desc,
    ws.ws_order_number,
    s.sum_cs_net_paid,
    SUM(ws.ws_net_paid) AS sum_ws_net_paid,
    COUNT(wr.wr_order_number) AS return_cnt,
    MAX(wr.wr_net_loss) AS max_return_loss
FROM sales_agg s
JOIN web_sales ws
    ON s.cs_order_number = ws.ws_order_number
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE td.t_shift = 'first'
  AND c.c_last_name = 'Hamilton'
  AND r.r_reason_desc = 'Damaged'
  AND ws.ws_quantity > 1
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_quantity > 0
    )
GROUP BY td.t_hour, c.c_last_name, r.r_reason_desc, ws.ws_order_number, s.sum_cs_net_paid
ORDER BY sum_ws_net_paid DESC
LIMIT 100
