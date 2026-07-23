WITH
    ss_agg AS (
        SELECT
            ss.ss_store_sk AS store_sk,
            ss.ss_item_sk AS item_sk,
            d_ss.d_year AS year,
            SUM(ss.ss_ext_sales_price) AS store_sales_amount,
            SUM(ss.ss_net_profit) AS store_net_profit,
            COUNT(*) AS store_sales_cnt,
            COUNT(DISTINCT ss.ss_ticket_number) AS distinct_ticket_cnt
        FROM store_sales ss
        JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
        JOIN item i_ss ON ss.ss_item_sk = i_ss.i_item_sk
        JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
        JOIN store s_ss ON ss.ss_store_sk = s_ss.s_store_sk
        WHERE d_ss.d_year BETWEEN 2001 AND 2002
        GROUP BY ss.ss_store_sk, ss.ss_item_sk, d_ss.d_year
    ),
    sr_agg AS (
        SELECT
            sr.sr_store_sk AS store_sk,
            sr.sr_item_sk AS item_sk,
            d_sr.d_year AS year,
            SUM(sr.sr_return_amt_inc_tax) AS returns_amount,
            SUM(sr.sr_fee) AS returns_fee,
            SUM(sr.sr_return_quantity) AS returns_qty,
            COUNT(*) AS returns_cnt
        FROM store_returns sr
        JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        JOIN item i_sr ON sr.sr_item_sk = i_sr.i_item_sk
        JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        JOIN store s_sr ON sr.sr_store_sk = s_sr.s_store_sk
        WHERE d_sr.d_year BETWEEN 2001 AND 2002
        GROUP BY sr.sr_store_sk, sr.sr_item_sk, d_sr.d_year
    ),
    ws_agg AS (
        SELECT
            ws.ws_item_sk AS item_sk,
            d_ws_sold.d_year AS year,
            SUM(ws.ws_ext_sales_price) AS web_sales_amount,
            SUM(ws.ws_net_profit) AS web_net_profit,
            COUNT(*) AS web_sales_cnt
        FROM web_sales ws
        JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
        JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
        JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
        JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
        JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        WHERE d_ws_sold.d_year BETWEEN 2001 AND 2002
        GROUP BY ws.ws_item_sk, d_ws_sold.d_year
    ),
    store_info AS (
        SELECT
            s.s_store_sk AS store_sk,
            s.s_store_name,
            s.s_state,
            d_closed.d_year AS closed_year
        FROM store s
        LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    )
SELECT
    si.s_store_name,
    si.s_state,
    ss_agg.year,
    i.i_category,
    SUM(ss_agg.store_sales_amount) AS total_store_sales,
    SUM(ss_agg.store_net_profit) AS total_store_profit,
    COALESCE(SUM(sr_agg.returns_amount), 0) AS total_returns_amount,
    COALESCE(SUM(ws_agg.web_sales_amount), 0) AS total_web_sales_amount,
    COALESCE(SUM(ws_agg.web_net_profit), 0) AS total_web_profit,
    SUM(ss_agg.distinct_ticket_cnt) AS total_distinct_store_tickets,
    SUM(ss_agg.store_sales_cnt) AS total_store_sales_transactions,
    COALESCE(SUM(sr_agg.returns_cnt), 0) AS total_return_transactions
FROM ss_agg
JOIN store_info si ON ss_agg.store_sk = si.store_sk
JOIN item i ON ss_agg.item_sk = i.i_item_sk
LEFT JOIN sr_agg ON ss_agg.store_sk = sr_agg.store_sk
    AND ss_agg.item_sk = sr_agg.item_sk
    AND ss_agg.year = sr_agg.year
LEFT JOIN ws_agg ON ss_agg.item_sk = ws_agg.item_sk
    AND ss_agg.year = ws_agg.year
GROUP BY si.s_store_name, si.s_state, ss_agg.year, i.i_category
ORDER BY total_store_sales DESC
LIMIT 100
