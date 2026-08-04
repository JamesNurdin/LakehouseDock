WITH
    inv_agg AS (
        SELECT inv_date_sk,
               SUM(inv_quantity_on_hand) AS inv_total_qty
        FROM inventory
        GROUP BY inv_date_sk
    ),
    ws_agg AS (
        SELECT ws_sold_date_sk,
               SUM(ws_ext_sales_price) AS ws_total_sales
        FROM web_sales
        GROUP BY ws_sold_date_sk
    )
SELECT
    d.d_date,
    cc.cc_name,
    cp.cp_department,
    s.s_store_name,
    p.p_promo_name,
    ss.ss_ext_sales_price,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ss.ss_ext_sales_price DESC) AS sales_rank,
    inv_agg.inv_total_qty,
    ws_agg.ws_total_sales,
    lr.lateral_total
FROM date_dim d
LEFT JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
LEFT JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
FULL OUTER JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
LEFT JOIN web_site wsite
    ON wsite.web_open_date_sk = d.d_date_sk
LEFT JOIN household_demographics hd
    ON hd.hd_demo_sk = ss.ss_hdemo_sk
LEFT JOIN time_dim t
    ON t.t_time_sk = ss.ss_sold_time_sk
LEFT JOIN inv_agg
    ON inv_agg.inv_date_sk = d.d_date_sk
LEFT JOIN ws_agg
    ON ws_agg.ws_sold_date_sk = d.d_date_sk
LEFT JOIN LATERAL (
        SELECT SUM(ss2.ss_ext_sales_price) AS lateral_total
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND ss2.ss_sold_date_sk = d.d_date_sk
) lr ON TRUE
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND p.p_channel_demo = 'N'
  AND i.inv_quantity_on_hand > 0
  AND wsite.web_country = 'United States'
ORDER BY ss.ss_ext_sales_price DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
