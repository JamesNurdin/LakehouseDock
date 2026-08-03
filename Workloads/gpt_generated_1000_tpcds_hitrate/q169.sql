WITH base AS (
    SELECT
        cc.cc_call_center_id,
        d_sales.d_year,
        t_sales.t_hour,
        s.s_store_name,
        s.s_tax_percentage,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        sr.sr_return_amt_inc_tax,
        ws.ws_ext_sales_price,
        ws.ws_quantity
    FROM store_sales ss
    JOIN date_dim d_sales
      ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales
      ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_return
      ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return
      ON sr.sr_return_time_sk = t_return.t_time_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d_sales.d_date_sk
     AND ws.ws_sold_time_sk = t_sales.t_time_sk
    JOIN date_dim d_ship
      ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN call_center cc
      ON cc.cc_closed_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2001
      AND t_sales.t_hour = 14
      AND s.s_tax_percentage > 5.0
      AND cc.cc_state = 'CA'
      AND ws.ws_quantity > 5
      AND sr.sr_return_amt_inc_tax > 1000
),
agg1 AS (
    SELECT
        cc_call_center_id,
        s_store_name,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(sr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ss_ticket_number) AS num_transactions
    FROM base
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_ticket_number = base.ss_ticket_number
          AND sr2.sr_return_amt > 100
    )
    GROUP BY cc_call_center_id, s_store_name
)
SELECT
    cc_call_center_id,
    s_store_name,
    total_store_sales,
    total_return_inc_tax,
    total_web_sales,
    num_transactions,
    (total_store_sales - total_return_inc_tax) AS net_sales_minus_returns,
    (total_store_sales + total_web_sales) AS combined_sales
FROM agg1
WHERE (total_store_sales + total_web_sales) > 10000
ORDER BY net_sales_minus_returns DESC
LIMIT 100
