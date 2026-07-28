WITH base AS (
    SELECT
        d.d_year,
        s.s_store_name,
        s.s_state,
        SUM(sr.sr_return_amt) AS store_return_total,
        SUM(cr.cr_return_amount) AS catalog_return_total,
        CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region_category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_number_employees > 50
      AND i.i_current_price BETWEEN 10 AND 100
      AND s.s_city = 'Los Angeles'
      AND EXISTS (
          SELECT 1
          FROM web_site ws
          WHERE ws.web_open_date_sk = d.d_date_sk
            AND ws.web_site_id = 'WS_001'
      )
    GROUP BY d.d_year,
             s.s_store_name,
             s.s_state,
             CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END
)
SELECT
    d_year,
    s_store_name,
    region_category,
    store_return_total,
    catalog_return_total,
    RANK() OVER (PARTITION BY d_year ORDER BY store_return_total DESC) AS store_return_rank
FROM base
ORDER BY d_year, store_return_rank
LIMIT 100
