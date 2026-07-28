WITH base AS (
    SELECT
        s.s_store_name,
        d.d_year,
        ss.ss_net_profit,
        ss.ss_quantity,
        c.c_customer_id,
        i.i_category,
        ca.ca_state,
        ca.ca_gmt_offset,
        p.p_discount_active,
        r.r_reason_desc,
        cc.cc_name,
        we.web_name
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Books'
      AND ca.ca_state = 'CA'
      AND ca.ca_gmt_offset BETWEEN -5.00 AND 0.00
      AND p.p_discount_active = 'Y'
)
SELECT
    s_store_name,
    d_year,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(ss_quantity) AS total_units_sold,
    CASE
        WHEN SUM(ss_net_profit) > 1000000 THEN 'High'
        WHEN SUM(ss_net_profit) > 500000  THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
FROM base
GROUP BY s_store_name, d_year
ORDER BY profit_rank
LIMIT 100
