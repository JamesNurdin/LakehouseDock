WITH promo_base AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price)               AS store_sales_amount,
        SUM(ss.ss_net_profit)                     AS store_net_profit,
        SUM(ws.ws_ext_sales_price)               AS web_sales_amount,
        SUM(ws.ws_net_profit)                     AS web_net_profit,
        SUM(cr.cr_net_loss)                       AS total_return_loss,
        COUNT(DISTINCT ss.ss_ticket_number)       AS store_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number)        AS web_txn_cnt,
        -- scalar sub‑query using DISTINCT
        (
            SELECT COUNT(DISTINCT cr2.cr_order_number)
            FROM catalog_returns cr2
            WHERE cr2.cr_refunded_customer_sk = ss.ss_customer_sk
        )                                          AS distinct_return_orders,
        DENSE_RANK() OVER (
            ORDER BY SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) DESC
        )                                           AS profit_rank,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH'
            ELSE 'NORMAL'
        END                                          AS sales_category
    FROM promotion p
    JOIN store_sales ss
        ON p.p_promo_sk = ss.ss_promo_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN web_sales ws
        ON p.p_promo_sk = ws.ws_promo_sk
    JOIN household_demographics hd_ws
        ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN customer_address ca_ws
        ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_returning_hdemo_sk = hd_ss.hd_demo_sk
        AND cr.cr_returning_addr_sk = ca_ss.ca_address_sk
    WHERE p.p_start_date_sk BETWEEN 2451545 AND 2451910                 -- predicate 1
      AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910                -- predicate 2
      AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910                -- predicate 3
      AND cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910            -- predicate 4
      AND ss.ss_ext_discount_amt > 150                                 -- predicate 5
      AND ws.ws_ext_discount_amt > 150                                 -- predicate 6
      AND ca_ss.ca_state = 'CA'                                         -- predicate 7
      AND ca_ws.ca_country = 'United States'                            -- predicate 8
      AND hd_ss.hd_vehicle_count >= 1                                   -- predicate 9
      AND hd_ws.hd_income_band_sk BETWEEN 3 AND 6                       -- predicate 10
    GROUP BY p.p_promo_sk, p.p_promo_id, p.p_promo_name, ss.ss_customer_sk
    HAVING SUM(ss.ss_ext_sales_price) > 50000                         -- additional filter
)
SELECT
    p_promo_id,
    p_promo_name,
    store_sales_amount,
    web_sales_amount,
    (store_net_profit + web_net_profit) AS total_net_profit,
    total_return_loss,
    store_txn_cnt,
    web_txn_cnt,
    distinct_return_orders,
    profit_rank,
    sales_category
FROM promo_base
ORDER BY total_net_profit DESC
LIMIT 100
