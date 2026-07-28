WITH base AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS store_sales_net,
        SUM(COALESCE(sr.sr_refunded_cash, 0)) AS store_returns_refunded,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS web_sales_net,
        SUM(COALESCE(wr.wr_refunded_cash, 0)) AS web_returns_refunded
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = ss.ss_item_sk
        AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_category = 'Electronics'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = 'High'
      AND ca.ca_country = 'United States'
      AND EXISTS (
          SELECT 1
          FROM call_center cc
          WHERE cc.cc_state = s.s_state
            AND cc.cc_open_date_sk = d.d_date_sk
            AND cc.cc_employees > 5000000
      )
    GROUP BY s.s_store_id, d.d_year, i.i_category
)
SELECT
    store_id,
    year,
    category,
    store_sales_net,
    store_returns_refunded,
    web_sales_net,
    web_returns_refunded,
    (store_sales_net - store_returns_refunded + web_sales_net - web_returns_refunded) AS net_total,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY (store_sales_net - store_returns_refunded + web_sales_net - web_returns_refunded) DESC) AS rn
FROM base
WHERE (store_sales_net - store_returns_refunded + web_sales_net - web_returns_refunded) > 10000
ORDER BY year, net_total DESC
LIMIT 100
