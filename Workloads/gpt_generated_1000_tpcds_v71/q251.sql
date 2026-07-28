-- Goal:  Analyze net paid revenue by year, call‑center division and promotion, including price‑category breakdowns and ranking, while joining all 13 TPC‑DS tables.
WITH ws_agg AS (
    SELECT
        ws_order_number,
        ws_sold_date_sk,
        ws_bill_customer_sk,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        ws_bill_addr_sk,
        ws_ship_customer_sk,
        ws_promo_sk,
        ws_web_page_sk,
        SUM(ws_net_paid)          AS total_net_paid,
        SUM(ws_ext_discount_amt)  AS total_discount
    FROM tpcds.web_sales
    GROUP BY
        ws_order_number,
        ws_sold_date_sk,
        ws_bill_customer_sk,
        ws_bill_cdemo_sk,
        ws_bill_hdemo_sk,
        ws_bill_addr_sk,
        ws_ship_customer_sk,
        ws_promo_sk,
        ws_web_page_sk
),
joined AS (
    SELECT
        d_sold.d_year,
        cc.cc_division_name,
        p.p_promo_name,
        c.c_customer_id,
        ca.ca_state,
        wp.wp_type,
        hd.hd_buy_potential,
        ws_agg.total_net_paid,
        ws_agg.total_discount,
        CASE WHEN ws_agg.total_discount > 0 THEN 'Discounted' ELSE 'Full Price' END AS price_category
    FROM ws_agg
    JOIN tpcds.date_dim d_sold
        ON ws_agg.ws_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.promotion p
        ON ws_agg.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c
        ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON ws_agg.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
        ON ws_agg.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN tpcds.web_page wp
        ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN tpcds.web_returns wr
        ON ws_agg.ws_order_number = wr.wr_order_number
    LEFT JOIN tpcds.time_dim t_ret
        ON wr.wr_returned_time_sk = t_ret.t_time_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN tpcds.date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN tpcds.time_dim t_cat_ret
        ON cr.cr_returned_time_sk = t_cat_ret.t_time_sk
    WHERE
        d_sold.d_year = 2001                                 -- filter 1
        AND cc.cc_mkt_id IN (1, 2, 3)                        -- filter 2
        AND p.p_discount_active = 'Y'                        -- filter 3
        AND wp.wp_type = 'content'                           -- filter 4
        AND c.c_birth_year BETWEEN 1950 AND 1960             -- filter 5
        AND hd.hd_buy_potential = 'high'                     -- filter 6
        AND t_ret.t_hour BETWEEN 9 AND 17                    -- filter 7
),
agg AS (
    SELECT
        d_year,
        cc_division_name,
        p_promo_name,
        price_category,
        SUM(total_net_paid)         AS sum_net_paid,
        AVG(total_discount)         AS avg_discount,
        COUNT(DISTINCT c_customer_id) AS uniq_customers
    FROM joined
    GROUP BY GROUPING SETS (
        (d_year, cc_division_name, p_promo_name, price_category),
        (d_year, cc_division_name, price_category),
        (d_year, price_category),
        (price_category)
    )
)
SELECT
    d_year,
    cc_division_name,
    p_promo_name,
    sum_net_paid,
    avg_discount,
    uniq_customers,
    price_category,
    ROW_NUMBER() OVER (ORDER BY sum_net_paid DESC) AS rank_by_net
FROM agg
ORDER BY d_year DESC NULLS LAST, cc_division_name, p_promo_name
LIMIT 100
