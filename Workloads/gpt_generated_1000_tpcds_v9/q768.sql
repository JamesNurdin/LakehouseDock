WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        p.p_promo_name,
        r.r_reason_desc,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(sr.sr_refunded_cash) AS total_store_returns,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_sales_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        MIN(ss.ss_net_profit) AS min_net_profit,
        MAX(ss.ss_net_profit) AS max_net_profit
    FROM store_sales ss
    RIGHT OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    WHERE s.s_state = 'CA'
      AND p.p_cost > 500.00
      AND p.p_response_target = 1
      AND sr.sr_return_ship_cost > 100.00
      AND sr.sr_reversed_charge < 500.00
      AND r.r_reason_desc LIKE '%price%'
      AND c.c_preferred_cust_flag = 'Y'
      AND ss.ss_net_profit > 1000.00
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
            AND ws2.ws_quantity > 30
      )
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        p.p_promo_name,
        r.r_reason_desc
)
SELECT
    b.s_store_id,
    b.s_store_name,
    b.p_promo_name,
    b.r_reason_desc,
    b.total_store_sales,
    b.total_store_returns,
    b.total_web_sales,
    b.avg_sales_discount,
    b.store_sales_count,
    b.store_returns_count,
    b.web_sales_count,
    b.min_net_profit,
    b.max_net_profit,
    ROW_NUMBER() OVER (PARTITION BY b.s_store_id ORDER BY b.total_store_sales DESC) AS sales_rank
FROM base b
ORDER BY b.total_store_sales DESC
LIMIT 100
