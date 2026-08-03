WITH sales_summary AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price)          AS total_sales,
        SUM(ws.ws_net_profit)               AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rnk_item
    FROM web_sales ws
    JOIN date_dim d  ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t  ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2001                         -- filter 1
      AND t.t_am_pm = 'PM'                        -- filter 2
      AND ws.ws_ext_sales_price > 0
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
)
SELECT
    d.d_date,
    i.i_item_id,
    i.i_brand,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    ss.total_sales,
    ss.total_profit,
    inv.inv_quantity_on_hand,
    st.s_store_name,
    cc.cc_name,
    promo.p_promo_name,
    wp.wp_url,
    ws_site.web_name,
    RANK() OVER (PARTITION BY i.i_item_id ORDER BY ss.total_sales DESC) AS sales_rank,
    CASE WHEN cr.cr_return_amount > 100 THEN 'HIGH' ELSE 'LOW' END AS return_level,
    avg_sub.avg_price
FROM sales_summary ss
JOIN web_sales ws            ON ws.ws_item_sk = ss.ws_item_sk AND ws.ws_sold_date_sk = ss.ws_sold_date_sk
JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t               ON ws.ws_sold_time_sk = t.t_time_sk
JOIN item i                   ON ws.ws_item_sk = i.i_item_sk
JOIN catalog_returns cr      ON cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc           ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN store st                 ON st.s_closed_date_sk = d.d_date_sk
JOIN promotion promo          ON ws.ws_promo_sk = promo.p_promo_sk
JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site         ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN (
        SELECT *
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
     ) inv                  ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_date_sk = d.d_date_sk
JOIN web_returns wr          ON wr.wr_item_sk = i.i_item_sk
                                 AND wr.wr_returned_date_sk = d.d_date_sk
                                 AND wr.wr_order_number = ws.ws_order_number
-- small dimension for a cartesian product
CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2 AS dummy) AS cross_dummy
-- lateral sub‑query referencing the preceding row
CROSS JOIN LATERAL (
        SELECT AVG(ws2.ws_ext_sales_price) AS avg_price
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = ws.ws_item_sk
          AND ws2.ws_sold_date_sk = ws.ws_sold_date_sk
     ) AS avg_sub
WHERE cc.cc_state = 'CA'                 -- filter 3
  AND promo.p_discount_active = 'Y'      -- filter 4
  AND i.i_color = 'BLUE'                  -- filter 5
ORDER BY ss.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
