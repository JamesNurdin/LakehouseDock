WITH agg AS (
    SELECT
        d.d_year AS d_year,
        we.web_name AS web_name,
        s.s_store_name AS store_name,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(wr.wr_net_loss) AS web_returns_loss,
        SUM(sr.sr_net_loss) AS store_returns_loss
    FROM
        date_dim d
        JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
        JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
        JOIN store s ON s.s_closed_date_sk = d.d_date_sk
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN web_site we ON we.web_open_date_sk = d.d_date_sk
        JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        d.d_year BETWEEN 1998 AND 2002
        AND cc.cc_country = 'USA'
        AND cp.cp_type = 'PROMO'
        AND ca.ca_state = 'TX'
        AND hd.hd_vehicle_count >= 1
        AND ib.ib_upper_bound > 50000
    GROUP BY
        d.d_year,
        we.web_name,
        s.s_store_name
)
SELECT
    d_year,
    web_name,
    store_name,
    web_sales_total,
    store_sales_total,
    web_returns_loss,
    store_returns_loss,
    (web_sales_total - web_returns_loss) / NULLIF((store_sales_total - store_returns_loss), 0) AS sales_to_return_ratio
FROM agg
WHERE (web_sales_total - web_returns_loss) / NULLIF((store_sales_total - store_returns_loss), 0) > 1.0
ORDER BY d_year, web_name
