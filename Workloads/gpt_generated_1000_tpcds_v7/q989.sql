WITH base AS (
    SELECT
        d.d_year,
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_brand,
        p.p_discount_active,
        ca.ca_gmt_offset,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        sr.sr_ticket_number,
        cs.cs_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        inv.inv_quantity_on_hand,
        wc.web_site_id,
        wp.wp_url,
        t.t_time_id
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON s.s_store_sk = ss.ss_store_sk
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
                           AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN item i ON i.i_item_sk = ss.ss_item_sk
    JOIN promotion p ON p.p_promo_sk = ss.ss_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                           AND inv.inv_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
    JOIN customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_site wc ON wc.web_open_date_sk = d.d_date_sk
),
agg AS (
    SELECT
        d_year,
        s_store_name,
        i_category,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit
    FROM base
    WHERE d_year BETWEEN 2000 AND 2002
      AND s_state = 'CA'
      AND i_brand = 'Brand#12'
      AND p_discount_active = 'Y'
      AND ca_gmt_offset = -6.00
    GROUP BY d_year, s_store_name, i_category
    HAVING SUM(ss_net_paid) > 10000
)
SELECT
    d_year,
    s_store_name,
    i_category,
    total_net_paid,
    total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS revenue_rank
FROM agg
ORDER BY d_year, revenue_rank
LIMIT 100
