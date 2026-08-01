WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        c.c_last_review_date,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        sr.sr_refunded_cash,
        sr.sr_store_credit,
        sr.sr_return_amt,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_order_number,
        ws.ws_ext_discount_amt,
        wp.wp_web_page_sk,
        wp.wp_rec_end_date,
        wp.wp_max_ad_count,
        wp.wp_image_count,
        wp.wp_type
    FROM tpcds.customer c
    JOIN tpcds.store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_rec_end_date = DATE '2000-09-02'
      AND wp.wp_max_ad_count >= 2
      AND wp.wp_image_count <= 6
      AND c.c_birth_month = 5
      AND c.c_last_review_date > 2452300
      AND sr.sr_refunded_cash > 1000.00
      AND sr.sr_store_credit < 500.00
),
agg AS (
    SELECT
        c_customer_id,
        c_birth_month,
        wp_type,
        CASE WHEN ws_sales_price > 100 THEN 'High' ELSE 'Low' END AS price_category,
        SUM(sr_refunded_cash) AS total_refunded_cash,
        SUM(sr_store_credit) AS total_store_credit,
        SUM(ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        AVG(ws_sales_price) AS avg_sales_price,
        MIN(ws_sales_price) AS min_sales_price,
        MAX(ws_sales_price) AS max_sales_price
    FROM base
    GROUP BY
        c_customer_id,
        c_birth_month,
        wp_type,
        CASE WHEN ws_sales_price > 100 THEN 'High' ELSE 'Low' END
)
SELECT
    a.c_customer_id,
    a.c_birth_month,
    a.wp_type,
    a.price_category,
    a.total_refunded_cash,
    a.total_store_credit,
    a.total_sales_amount,
    a.distinct_orders,
    a.avg_sales_price,
    a.min_sales_price,
    a.max_sales_price,
    (SELECT AVG(ws2.ws_sales_price) FROM tpcds.web_sales ws2) AS overall_avg_sales_price,
    RANK() OVER (ORDER BY a.total_refunded_cash DESC) AS refund_rank,
    SUM(a.total_refunded_cash) OVER (
        PARTITION BY a.price_category
        ORDER BY a.total_refunded_cash
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_refund_by_category
FROM agg a
ORDER BY a.total_refunded_cash DESC
LIMIT 100
