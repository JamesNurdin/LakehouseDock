WITH joined AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        ss.ss_ext_tax,
        ss.ss_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        wr.wr_return_tax,
        td.t_shift,
        td.t_hour
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE td.t_shift = 'second'
      AND td.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_amount > 100.00
      AND ss.ss_ext_tax > 1.00
      AND ss.ss_net_profit < 0
      AND wr.wr_return_tax > 10.00
      AND ws.ws_quantity >= 2
)
SELECT
    t_shift,
    t_hour,
    COUNT(DISTINCT cr_order_number) AS num_catalog_returns,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    AVG(ss_net_profit) AS avg_store_net_profit,
    SUM(wr_return_tax) AS total_web_return_tax,
    MAX(ws_ext_sales_price) AS max_web_sales_price,
    MIN(ss_ext_tax) AS min_store_ext_tax,
    SUM(SUM(cr_return_amount)) OVER (
        PARTITION BY t_shift
        ORDER BY t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_return_amount
FROM joined
GROUP BY t_shift, t_hour
ORDER BY t_shift, t_hour
