WITH
    store_sales_agg AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_addr_sk,
            ss.ss_hdemo_sk,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            COUNT(*) AS sales_cnt
        FROM store_sales ss TABLESAMPLE BERNOULLI (10)
        GROUP BY ss.ss_sold_date_sk, ss.ss_addr_sk, ss.ss_hdemo_sk
    ),
    orders_without_returns AS (
        SELECT ws.ws_order_number
        FROM web_sales ws
        EXCEPT
        SELECT wr.wr_order_number
        FROM web_returns wr
    ),
    ranked_sales AS (
        SELECT
            ss_agg.ss_sold_date_sk,
            d.d_date_sk,
            d.d_year,
            d.d_month_seq,
            ca.ca_state,
            ca.ca_city,
            ss_agg.total_sales,
            ss_agg.sales_cnt,
            ws.ws_order_number,
            ws.ws_quantity,
            ws.ws_ext_sales_price,
            wp.wp_type,
            sm.sm_type AS ship_type,
            r.r_reason_desc,
            ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ss_agg.total_sales DESC) AS sales_rank,
            CASE WHEN ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ss_agg.total_sales DESC) = 1 THEN 'Top' ELSE 'Other' END AS rank_category,
            hd.hd_income_band_sk,
            ib.ib_upper_bound
        FROM store_sales_agg ss_agg
        JOIN date_dim d ON ss_agg.ss_sold_date_sk = d.d_date_sk
        JOIN customer_address ca ON ss_agg.ss_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN orders_without_returns owr ON ws.ws_order_number = owr.ws_order_number
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE d.d_year = 2020
          AND ib.ib_upper_bound >= 50000
          AND sm.sm_type = 'AIR'
          AND ca.ca_state = 'CA'
          AND (r.r_reason_desc LIKE '%defect%' OR r.r_reason_desc IS NULL)
          AND ws.ws_quantity > 2
    )
SELECT DISTINCT
    rs.d_year,
    rs.d_month_seq,
    rs.ca_state,
    rs.ca_city,
    rs.total_sales,
    rs.sales_cnt,
    rs.sales_rank,
    rs.rank_category,
    rs.ship_type,
    rs.wp_type,
    rs.r_reason_desc,
    lr.return_cnt
FROM ranked_sales rs
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS return_cnt
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk = rs.d_date_sk
) AS lr ON true
ORDER BY rs.total_sales DESC
LIMIT 100
