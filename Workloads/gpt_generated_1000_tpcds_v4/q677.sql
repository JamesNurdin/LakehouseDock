WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        ca.ca_state,
        SUM(ss.ss_net_profit)               AS store_profit,
        SUM(cs.cs_net_profit)               AS catalog_profit,
        SUM(ws.ws_net_profit)               AS web_profit,
        COUNT(DISTINCT cs.cs_order_number)  AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number)  AS web_orders
    FROM store s
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    -- catalog sales linked through item and date
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
       AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p2
        ON cs.cs_promo_sk = p2.p_promo_sk
    -- catalog returns (optional left join to keep sales rows)
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    -- web sales linked through item and date
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND ca.ca_country = 'United States'
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_item_sk = i.i_item_sk
            AND ws2.ws_net_profit > 1000
            AND ws2.ws_sold_date_sk = d.d_date_sk
      )
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, ca.ca_state
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    b.s_store_id,
    b.s_store_name,
    b.d_year,
    b.ca_state,
    b.store_profit,
    b.catalog_profit,
    b.web_profit,
    b.catalog_orders,
    b.web_orders,
    RANK() OVER (PARTITION BY b.d_year ORDER BY b.store_profit DESC) AS profit_rank
FROM base b
ORDER BY b.d_year, profit_rank
