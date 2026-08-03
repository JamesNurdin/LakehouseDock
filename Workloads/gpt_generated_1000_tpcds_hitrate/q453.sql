WITH base AS (
    SELECT
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_brand,
        cp.cp_department,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN income_band ib ON hd_ws_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        t.t_hour BETWEEN 8 AND 17
        AND i.i_current_price > 100
        AND s.s_state = 'CA'
        AND cc.cc_market_manager = 'John Doe'
        AND ws.ws_net_paid_inc_ship_tax > 1000
        AND wp.wp_char_count > 2000
        AND hd_ws_bill.hd_buy_potential = '5001-10000'
    GROUP BY
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_brand,
        cp.cp_department
)
SELECT
    s_state,
    i_category,
    i_brand,
    SUM(total_sales) AS sum_sales,
    SUM(total_returns) AS sum_returns,
    SUM(distinct_pages) AS sum_distinct_pages,
    SUM(total_sales - total_returns) AS sum_net_amount
FROM base b
WHERE EXISTS (
    SELECT 1
    FROM catalog_page cp2
    WHERE cp2.cp_department = b.cp_department
      AND cp2.cp_catalog_number > 5
)
GROUP BY ROLLUP (s_state, i_category, i_brand)
HAVING SUM(total_sales) > 5000 OR GROUPING(s_state) = 1
ORDER BY sum_net_amount DESC
LIMIT 100
