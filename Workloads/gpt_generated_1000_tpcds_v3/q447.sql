WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_sales.d_date,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_tax) AS total_ext_tax
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN inventory i ON i.inv_date_sk = d_sales.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_sales.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d_sales.d_date_sk
    JOIN web_sales ws ON ws.ws_order_number = ss.ss_ticket_number
                       AND ws.ws_item_sk = ss.ss_item_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim d_web_open ON wsite.web_open_date_sk = d_web_open.d_date_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d_sales.d_year = 2002
      AND s.s_state = 'CA'
      AND cc.cc_gmt_offset > -5.00
      AND cp.cp_department = 'Sports'
      AND hd.hd_buy_potential = '501-1000'
      AND r_sr.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, d_sales.d_date
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.d_date,
    a.total_sales,
    a.total_returns,
    a.total_net_profit - a.total_returns AS net_profit,
    CASE WHEN a.total_ext_tax > 500 THEN 'High Tax' ELSE 'Low Tax' END AS tax_category,
    RANK() OVER (PARTITION BY a.s_state ORDER BY a.total_sales DESC) AS sales_rank_by_state,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.d_date) AS sales_day_sequence
FROM agg a
ORDER BY a.total_sales DESC, a.s_store_id
LIMIT 100
