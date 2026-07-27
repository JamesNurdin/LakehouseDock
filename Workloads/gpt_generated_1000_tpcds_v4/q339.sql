WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
),
base AS (
    SELECT
        s.s_store_name AS store_name,
        d0.d_year AS d_year,
        SUM(ss.ss_net_profit) AS store_year_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_year_sales,
        SUM(ws.ws_ext_sales_price) AS web_year_sales,
        SUM(inv_agg.total_on_hand) AS total_on_hand,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM date_dim d0
    JOIN store_sales ss ON ss.ss_sold_date_sk = d0.d_date_sk
    JOIN time_dim t0 ON ss.ss_sold_time_sk = t0.t_time_sk
    JOIN household_demographics hd0 ON ss.ss_hdemo_sk = hd0.hd_demo_sk
    JOIN customer_address ca0 ON ss.ss_addr_sk = ca0.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d0.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d0.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d0.d_date_sk
    JOIN inv_agg ON inv_agg.inv_date_sk = inv.inv_date_sk
                 AND inv_agg.inv_item_sk = inv.inv_item_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d_wr_returned ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
    JOIN time_dim t_wr_returned ON wr.wr_returned_time_sk = t_wr_returned.t_time_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d0.d_year = 2001
      AND s.s_state = 'CA'
      AND ca0.ca_country = 'United States'
    GROUP BY s.s_store_name, d0.d_year
)
SELECT
    store_name,
    d_year,
    store_year_profit,
    catalog_year_sales,
    web_year_sales,
    total_on_hand,
    store_return_count,
    web_return_count,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY store_year_profit DESC) AS profit_rank
FROM base
ORDER BY d_year, profit_rank
LIMIT 100
