WITH joined_data AS (
    SELECT
        c.c_customer_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_ext_sales_price,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_ext_tax,
        ws.ws_net_paid,
        ws.ws_ext_tax,
        sr.sr_net_loss,
        wp.wp_image_count,
        hd.hd_buy_potential,
        t.t_hour
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND hd.hd_buy_potential = '1001-5000'
      AND ib.ib_upper_bound <= 50000
      AND wp.wp_image_count > 3
)
SELECT
    c_customer_id,
    ib_lower_bound,
    ib_upper_bound,
    CASE WHEN ss_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
    COUNT(DISTINCT ss_ticket_number) AS store_txn_cnt,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(sr_net_loss) AS total_returns_loss,
    AVG(ss_ext_discount_amt) AS avg_store_discount,
    MIN(ss_ext_tax) AS min_store_tax,
    MAX(ws_ext_tax) AS max_web_tax
FROM joined_data
GROUP BY
    c_customer_id,
    ib_lower_bound,
    ib_upper_bound,
    CASE WHEN ss_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END
LIMIT 100
