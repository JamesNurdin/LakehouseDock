WITH
sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_addr_sk,
        ss.ss_hdemo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        MAX(ss.ss_sold_date_sk) AS max_sold_date_sk
    FROM store_sales ss
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, ss.ss_addr_sk, ss.ss_hdemo_sk
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        sr.sr_addr_sk,
        sr.sr_hdemo_sk,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(*) AS return_cnt,
        MAX(sr.sr_returned_date_sk) AS max_return_date_sk
    FROM store_returns sr
    JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
    JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY sr.sr_store_sk, sr.sr_item_sk, sr.sr_addr_sk, sr.sr_hdemo_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_ship_mode_sk,
        ws.ws_item_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk,
        SUM(ws.ws_ext_sales_price) AS web_total_sales,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN time_dim t_web ON ws.ws_sold_time_sk = t_web.t_time_sk
    JOIN item i3 ON ws.ws_item_sk = i3.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws.ws_ship_mode_sk, ws.ws_item_sk, ws.ws_bill_hdemo_sk, ws.ws_bill_addr_sk
),
store_ids_with_sales AS (
    SELECT DISTINCT ss_store_sk FROM sales_agg
),
store_ids_with_returns AS (
    SELECT DISTINCT sr_store_sk FROM returns_agg
),
stores_both AS (
    SELECT ss_store_sk FROM store_ids_with_sales
    INTERSECT
    SELECT sr_store_sk FROM store_ids_with_returns
),
final_data AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_market_manager,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        ca.ca_state,
        ca.ca_city,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COALESCE(sa.total_sales, 0) AS total_sales,
        COALESCE(sa.total_profit, 0) AS total_profit,
        COALESCE(ra.total_returns, 0) AS total_returns,
        COALESCE(ws.web_total_sales, 0) AS web_total_sales,
        CASE
            WHEN COALESCE(sa.total_profit, 0) > 0 THEN 'Profit'
            ELSE 'Loss'
        END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY COALESCE(sa.total_sales, 0) DESC) AS rn,
        LAG(COALESCE(sa.total_sales, 0)) OVER (PARTITION BY s.s_store_sk ORDER BY COALESCE(sa.total_sales, 0) DESC) AS prev_sales,
        SUM(COALESCE(sa.total_sales, 0)) OVER (
            PARTITION BY s.s_store_sk
            ORDER BY COALESCE(sa.total_sales, 0) DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_sales,
        (SELECT AVG(i_current_price) FROM item) AS avg_item_price
    FROM sales_agg sa
    JOIN store s ON sa.ss_store_sk = s.s_store_sk
    JOIN item i ON sa.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sa.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN returns_agg ra ON ra.sr_store_sk = s.s_store_sk AND ra.sr_item_sk = i.i_item_sk
    LEFT JOIN web_sales_agg ws ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON sa.ss_addr_sk = ca.ca_address_sk
    JOIN stores_both sb ON s.s_store_sk = sb.ss_store_sk
    WHERE s.s_market_manager = 'John Sizemore'
      AND i.i_current_price > (SELECT AVG(i_current_price) FROM item)
)
SELECT
    s_store_name,
    i_item_id,
    i_product_name,
    total_sales,
    total_returns,
    web_total_sales,
    profit_category,
    rn,
    prev_sales,
    running_sales,
    avg_item_price,
    ca_state,
    ca_city,
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound
FROM final_data
WHERE rn <= 100
ORDER BY total_sales DESC
LIMIT 100
