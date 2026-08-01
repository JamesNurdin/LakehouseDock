WITH
  full_time_cr AS (
    SELECT
      t.t_time_sk,
      t.t_time_id,
      t.t_hour,
      t.t_am_pm,
      cr.cr_returned_date_sk,
      cr.cr_return_amount
    FROM
      time_dim t
    FULL OUTER JOIN catalog_returns cr
      ON cr.cr_returned_time_sk = t.t_time_sk
  ),
  intersected AS (
    SELECT ss_ticket_number AS key_id
    FROM store_sales ss
    INTERSECT
    SELECT ws_order_number
    FROM web_sales ws
  ),
  main AS (
    SELECT
      ft.t_time_id,
      ft.t_hour,
      ft.t_am_pm,
      ss.ss_ticket_number,
      ss.ss_net_profit,
      ws.ws_ext_ship_cost,
      sr.sr_return_amt,
      wr.wr_return_amt,
      (
        SELECT SUM(srr.sr_return_amt)
        FROM store_returns srr
        WHERE srr.sr_ticket_number = ss.ss_ticket_number
      ) AS total_store_return_for_ticket,
      ROW_NUMBER() OVER (PARTITION BY ft.t_hour ORDER BY ss.ss_net_profit DESC) AS profit_rank,
      ft.cr_return_amount
    FROM
      full_time_cr ft
    JOIN store_sales ss
      ON ss.ss_sold_time_sk = ft.t_time_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws
      ON ws.ws_sold_time_sk = ft.t_time_sk
    JOIN web_returns wr
      ON wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
    WHERE
      ft.t_am_pm = 'PM'
      AND ft.t_hour BETWEEN 12 AND 18
      AND ss.ss_net_profit > 0
      AND ws.ws_ext_ship_cost > 500
      AND ss.ss_ticket_number IN (SELECT key_id FROM intersected)
  )
SELECT *
FROM main
ORDER BY profit_rank, ss_net_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
