WITH store_ret AS (
    SELECT
        'store' AS return_type,
        s.s_store_name AS location_name,
        td.t_shift AS shift,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE td.t_shift = 'first'
      AND i.i_category = 'Electronics'
    GROUP BY s.s_store_name, td.t_shift
),
web_ret AS (
    SELECT
        'web' AS return_type,
        CAST(ws.ws_web_site_sk AS varchar) AS location_name,
        td.t_shift AS shift,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE td.t_shift = 'first'
      AND i.i_category = 'Electronics'
    GROUP BY ws.ws_web_site_sk, td.t_shift
)
SELECT return_type, location_name, shift, total_return_amount, total_net_loss
FROM store_ret
UNION ALL
SELECT return_type, location_name, shift, total_return_amount, total_net_loss
FROM web_ret
