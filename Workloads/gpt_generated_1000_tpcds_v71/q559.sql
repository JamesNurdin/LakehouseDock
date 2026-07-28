WITH per_customer AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_loss,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE ws.ws_quantity > 1
      AND ws.ws_net_profit > 0
      AND w.w_gmt_offset = -5.00
      AND ca.ca_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = ws.ws_promo_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_state, hd.hd_income_band_sk
    HAVING SUM(ws.ws_net_profit) > 500
)
SELECT
    hd_income_band_sk,
    COUNT(*) AS customer_cnt,
    AVG(total_web_profit) AS avg_web_profit,
    AVG(total_store_loss) AS avg_store_loss,
    SUM(total_sales) AS sum_sales,
    AVG(distinct_pages) AS avg_distinct_pages
FROM per_customer
WHERE total_sales > 1000
GROUP BY hd_income_band_sk
HAVING AVG(total_web_profit) > 200
ORDER BY avg_web_profit DESC
LIMIT 100
