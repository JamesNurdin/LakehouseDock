WITH
    ws AS (
        SELECT *
        FROM tpcds.web_sales
        TABLESAMPLE BERNOULLI (10)
        WHERE ws_wholesale_cost > 50
    ),
    wp_filt AS (
        SELECT *
        FROM tpcds.web_page
        WHERE wp_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    ),
    sm_filt AS (
        SELECT *
        FROM tpcds.ship_mode
        WHERE sm_type = 'EXPRESS'
    ),
    promo_filt AS (
        SELECT *
        FROM tpcds.promotion
        WHERE p_discount_active = 'Y'
    ),
    cd_filt AS (
        SELECT *
        FROM tpcds.customer_demographics
        WHERE cd_credit_rating = 'Excellent'
    ),
    joined_base AS (
        SELECT
            ws.ws_item_sk,
            ws.ws_web_site_sk,
            ws.ws_promo_sk,
            ws.ws_ship_mode_sk,
            ws.ws_web_page_sk,
            ws.ws_sold_date_sk,
            ws.ws_sales_price,
            ws.ws_net_paid,
            ws.ws_wholesale_cost,
            cd.cd_demo_sk,
            wp.wp_web_page_sk,
            sm.sm_ship_mode_sk,
            promo.p_promo_sk,
            site.web_site_sk,
            wr.wr_return_quantity
        FROM ws
        INNER JOIN cd_filt cd
            ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        INNER JOIN wp_filt wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        INNER JOIN sm_filt sm
            ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN promo_filt promo
            ON ws.ws_promo_sk = promo.p_promo_sk
        INNER JOIN tpcds.web_site site
            ON ws.ws_web_site_sk = site.web_site_sk
        LEFT JOIN tpcds.web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
        FULL OUTER JOIN tpcds.store_returns sr
            ON sr.sr_cdemo_sk = cd.cd_demo_sk
    ),
    with_lag AS (
        SELECT
            *,
            LAG(ws_sales_price) OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS prev_sales_price
        FROM joined_base
    )
SELECT
    ws_item_sk,
    ws_web_site_sk,
    ws_promo_sk,
    ws_ship_mode_sk,
    ws_web_page_sk,
    ws_sold_date_sk,
    SUM(ws_net_paid) AS total_net_paid,
    AVG(ws_wholesale_cost) AS avg_wholesale_cost,
    COUNT(*) AS sales_cnt,
    MIN(ws_sold_date_sk) AS first_sold_date,
    MAX(ws_sold_date_sk) AS last_sold_date,
    MAX(prev_sales_price) AS prev_sales_price,
    (
        SELECT SUM(p_cost)
        FROM promo_filt p_sub
        WHERE p_sub.p_promo_sk = with_lag.ws_promo_sk
    ) AS promo_total_cost
FROM with_lag
GROUP BY
    ws_item_sk,
    ws_web_site_sk,
    ws_promo_sk,
    ws_ship_mode_sk,
    ws_web_page_sk,
    ws_sold_date_sk,
    prev_sales_price
ORDER BY total_net_paid DESC
LIMIT 100
