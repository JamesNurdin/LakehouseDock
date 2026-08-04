WITH
    /* Sampled fact tables */
    sampled_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    sampled_web_sales AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    sampled_call_center AS (
        SELECT *
        FROM call_center
        TABLESAMPLE BERNOULLI (5)
    ),

    /* Dimensions for store sales */
    sales_with_dims AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            ss.ss_item_sk,
            ss.ss_store_sk,
            ss.ss_customer_sk,
            ss.ss_promo_sk,
            ss.ss_net_paid,
            d.d_year,
            i.i_category,
            p.p_promo_name,
            s.s_store_name,
            c.c_first_name,
            c.c_last_name,
            hd.hd_income_band_sk,
            ib.ib_lower_bound,
            ARRAY[ss.ss_store_sk, ss.ss_customer_sk] AS store_customer_arr
        FROM sampled_sales ss
        JOIN date_dim d          ON ss.ss_sold_date_sk   = d.d_date_sk
        JOIN item i               ON ss.ss_item_sk       = i.i_item_sk
        JOIN store s              ON ss.ss_store_sk      = s.s_store_sk
        JOIN promotion p          ON ss.ss_promo_sk      = p.p_promo_sk
        JOIN customer c          ON ss.ss_customer_sk   = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ),

    /* Unnest the array built in the previous CTE */
    unnest_array AS (
        SELECT
            swd.ss_ticket_number,
            elem AS store_or_customer_sk
        FROM sales_with_dims swd
        CROSS JOIN UNNEST(swd.store_customer_arr) AS t(elem)
    ),

    /* Store returns (left‑joined later) */
    returns_filtered AS (
        SELECT
            sr.sr_ticket_number,
            dr.d_year   AS return_year,
            r.r_reason_desc,
            sr.sr_store_sk,
            sr.sr_customer_sk,
            sr.sr_return_amt
        FROM store_returns sr
        JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
        JOIN reason r     ON sr.sr_reason_sk      = r.r_reason_sk
        JOIN store s2     ON sr.sr_store_sk       = s2.s_store_sk
    ),

    /* Web sales with its own dimensions */
    web_joined AS (
        SELECT
            ws.ws_order_number,
            ws.ws_sold_date_sk,
            ws.ws_bill_customer_sk,
            ws.ws_net_paid,
            d.d_year,
            ws.ws_item_sk,
            i.i_category,
            ws.ws_promo_sk,
            p.p_promo_name,
            ws.ws_web_page_sk,
            wp.wp_url,
            ws.ws_web_site_sk,
            wsite.web_name
        FROM sampled_web_sales ws
        JOIN date_dim d   ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i       ON ws.ws_item_sk     = i.i_item_sk
        JOIN promotion p  ON ws.ws_promo_sk    = p.p_promo_sk
        JOIN web_page wp  ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    ),

    /* Call center data linked through the open date */
    call_center_joined AS (
        SELECT
            cc.cc_call_center_id,
            d_cc.d_year AS open_year
        FROM sampled_call_center cc
        JOIN date_dim d_cc ON cc.cc_open_date_sk = d_cc.d_date_sk
    ),

    /* Stores that have sales but no matching return */
    stores_with_sales AS (
        SELECT DISTINCT ss_store_sk AS store_sk FROM store_sales
    ),
    stores_with_returns AS (
        SELECT DISTINCT sr_store_sk AS store_sk FROM store_returns
    ),
    stores_sales_not_returned AS (
        SELECT store_sk FROM stores_with_sales
        EXCEPT
        SELECT store_sk FROM stores_with_returns
    ),

    /* Combine sales with optional return information */
    combined AS (
        SELECT
            swd.ss_ticket_number,
            swd.d_year,
            swd.i_category,
            swd.p_promo_name,
            swd.s_store_name,
            swd.c_first_name,
            swd.c_last_name,
            swd.hd_income_band_sk,
            swd.ib_lower_bound,
            swd.ss_net_paid,
            swd.ss_store_sk,
            swd.ss_customer_sk,
            rf.r_reason_desc,
            rf.sr_return_amt
        FROM sales_with_dims swd
        LEFT JOIN returns_filtered rf
            ON swd.ss_ticket_number = rf.sr_ticket_number
    )
SELECT
    c.d_year,
    c.i_category,
    c.p_promo_name,
    c.s_store_name,
    SUM(c.ss_net_paid)                     AS total_sales,
    SUM(COALESCE(c.sr_return_amt, 0))      AS total_returns,
    COUNT(DISTINCT c.ss_ticket_number)     AS num_transactions,
    COUNT(DISTINCT ua.store_or_customer_sk) AS distinct_store_customer_keys,
    COUNT(DISTINCT ccj.cc_call_center_id)  AS num_call_centers
FROM combined c
JOIN stores_sales_not_returned snr
    ON c.ss_store_sk = snr.store_sk
LEFT JOIN unnest_array ua
    ON c.ss_ticket_number = ua.ss_ticket_number
JOIN call_center_joined ccj
    ON c.d_year = ccj.open_year
JOIN web_joined wj
    ON c.ss_customer_sk = wj.ws_bill_customer_sk
   AND c.d_year = wj.d_year
GROUP BY ROLLUP (c.d_year, c.i_category, c.p_promo_name, c.s_store_name)
ORDER BY c.d_year DESC NULLS LAST, total_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
