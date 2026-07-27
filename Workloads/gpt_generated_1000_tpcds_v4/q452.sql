WITH base AS (
    SELECT
        dd.d_year,
        dd.d_month_seq,
        w.w_warehouse_name,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_reversed_charge) AS avg_reversed_charge,
        COUNT(DISTINCT sr.sr_item_sk) AS distinct_items_returned,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM date_dim dd
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = dd.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = dd.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE dd.d_year = 2001
      AND dd.d_month_seq BETWEEN 1200 AND 1300
      AND sr.sr_reversed_charge > 10
      AND w.w_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM web_site ws
          WHERE (ws.web_open_date_sk = dd.d_date_sk OR ws.web_close_date_sk = dd.d_date_sk)
            AND ws.web_city = 'Seattle'
            AND ws.web_suite_number = 'Suite 150 '
      )
    GROUP BY dd.d_year, dd.d_month_seq, w.w_warehouse_name
)
SELECT
    d_year,
    d_month_seq,
    w_warehouse_name,
    total_return_amt,
    avg_reversed_charge,
    distinct_items_returned,
    total_inventory_on_hand
FROM base
ORDER BY total_return_amt DESC
LIMIT 100
