WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_net_loss,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        i.i_item_sk,
        i.i_color,
        i.i_brand,
        d.d_date_sk,
        d.d_year,
        t.t_time_sk,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        ca.ca_address_sk,
        s.s_store_sk,
        s.s_state,
        sm.sm_ship_mode_sk,
        w.w_warehouse_sk,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d                     ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t                     ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i                         ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca            ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s                        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN catalog_returns cr        ON cr.cr_item_sk = i.i_item_sk
                                        AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm              ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w               ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws              ON ws.ws_item_sk = i.i_item_sk
                                        AND ws.ws_sold_date_sk = d.d_date_sk
    FULL OUTER JOIN inventory inv       ON inv.inv_item_sk = i.i_item_sk
                                        AND inv.inv_date_sk = d.d_date_sk
    WHERE i.i_color = 'pink'
      AND i.i_brand = 'amalgamalg #1'
      AND s.s_state = 'CA'
      AND d.d_year = 2001
      AND hd.hd_vehicle_count >= 2
      AND cr.cr_net_loss > 0
),
expanded AS (
    SELECT
        b.*, u.measure
    FROM base b
    CROSS JOIN LATERAL (
        SELECT ARRAY[b.ss_quantity, CAST(b.ss_ext_sales_price AS double)] AS arr
    ) a
    CROSS JOIN UNNEST(a.arr) AS u(measure)
),
agg AS (
    SELECT
        s.s_store_sk,
        i.i_item_sk,
        d.d_year,
        SUM(e.ss_ext_sales_price) AS total_store_sales,
        SUM(e.ws_net_profit)        AS total_web_profit,
        SUM(e.cr_net_loss)          AS total_return_loss,
        COUNT(*)                    AS txn_count
    FROM expanded e
    JOIN store s ON e.ss_store_sk = s.s_store_sk
    JOIN item i ON e.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON e.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, i.i_item_sk, d.d_year
)
SELECT
    a.s_store_sk,
    a.i_item_sk,
    a.d_year,
    AVG(a.total_store_sales) OVER (PARTITION BY a.d_year) AS avg_store_sales_per_year,
    a.total_store_sales,
    a.total_web_profit,
    a.total_return_loss,
    a.txn_count
FROM agg a
WHERE a.total_store_sales > 1000
  AND a.total_web_profit > 0
  AND a.total_return_loss > 0
  AND a.d_year = 2001
  AND a.txn_count >= 5
ORDER BY a.total_store_sales DESC
LIMIT 100
