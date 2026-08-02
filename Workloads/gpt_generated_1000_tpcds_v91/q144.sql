WITH
    store_sales_agg AS (
        SELECT
            ss.ss_store_sk AS store_sk,
            ss.ss_promo_sk AS promo_sk,
            ss.ss_sold_date_sk AS sold_date_sk,
            ss.ss_sold_time_sk AS sold_time_sk,
            SUM(ss.ss_net_paid) AS total_net_paid,
            SUM(ss.ss_net_profit) AS total_net_profit,
            COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
            COALESCE(SUM(sr.sr_net_loss), 0) AS total_net_loss
        FROM store_sales ss
        LEFT JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_item_sk = ss.ss_item_sk
        INNER JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        INNER JOIN promotion p
            ON ss.ss_promo_sk = p.p_promo_sk
        INNER JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        INNER JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE ss.ss_quantity > 1
          AND ss.ss_net_paid > 100
          AND t.t_sub_shift = 'morning'
          AND t.t_hour BETWEEN 9 AND 17
          AND p.p_channel_tv = 'Y'
          AND ca.ca_state = 'CA'
          AND s.s_state = 'TX'
        GROUP BY ss.ss_store_sk, ss.ss_promo_sk, ss.ss_sold_date_sk, ss.ss_sold_time_sk
    ),
    web_sales_agg AS (
        SELECT
            NULL AS store_sk,
            ws.ws_promo_sk AS promo_sk,
            ws.ws_sold_date_sk AS sold_date_sk,
            ws.ws_sold_time_sk AS sold_time_sk,
            SUM(ws.ws_net_paid) AS total_net_paid,
            SUM(ws.ws_net_profit) AS total_net_profit,
            COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
            0 AS total_net_loss
        FROM web_sales ws
        INNER JOIN time_dim t
            ON ws.ws_sold_time_sk = t.t_time_sk
        INNER JOIN promotion p
            ON ws.ws_promo_sk = p.p_promo_sk
        INNER JOIN customer_address ca
            ON ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE ws.ws_quantity > 1
          AND ws.ws_net_paid > 100
          AND t.t_sub_shift = 'morning'
          AND ca.ca_state = 'CA'
          AND p.p_channel_tv = 'Y'
        GROUP BY ws.ws_promo_sk, ws.ws_sold_date_sk, ws.ws_sold_time_sk
    )
SELECT
    combined.store_sk,
    combined.promo_sk,
    combined.sold_date_sk,
    combined.sold_time_sk,
    combined.total_net_paid,
    combined.total_net_profit,
    combined.distinct_customers,
    combined.total_net_loss,
    CASE
        WHEN combined.total_net_profit >= 20000 THEN 'High'
        WHEN combined.total_net_profit >= 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY combined.total_net_profit DESC) AS global_rn,
    (
        SELECT SUM(ss2.ss_quantity)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = combined.store_sk
    ) AS store_total_quantity
FROM (
    SELECT
        store_sk,
        promo_sk,
        sold_date_sk,
        sold_time_sk,
        total_net_paid,
        total_net_profit,
        distinct_customers,
        total_net_loss,
        'store' AS sales_channel
    FROM store_sales_agg
    UNION ALL
    SELECT
        store_sk,
        promo_sk,
        sold_date_sk,
        sold_time_sk,
        total_net_paid,
        total_net_profit,
        distinct_customers,
        total_net_loss,
        'web' AS sales_channel
    FROM web_sales_agg
) combined
ORDER BY combined.total_net_profit DESC
LIMIT 100
