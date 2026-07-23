WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        i_ss.i_category,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(sr.sr_return_quantity) AS total_store_return_qty,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs.cs_quantity) AS total_catalog_quantity,
        SUM(wr.wr_return_amt) AS total_web_returns,
        SUM(wr.wr_return_quantity) AS total_web_return_qty,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(p_ss.p_cost) AS avg_promo_cost,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i_ss ON ss.ss_item_sk = i_ss.i_item_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i_ss.i_item_sk
        AND cs.cs_sold_time_sk = t_ss.t_time_sk
        AND cs.cs_bill_customer_sk = c_ss.c_customer_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i_ss.i_item_sk
        AND wr.wr_returned_time_sk = t_ss.t_time_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE s.s_country = 'United States'
        AND s.s_manager = 'Matt Frederick'
        AND i_ss.i_color = 'Red'
        AND p_ss.p_promo_name LIKE '%Holiday%'
        AND r_sr.r_reason_desc = 'Damaged'
        AND wp.wp_max_ad_count > 2
        AND wp.wp_link_count BETWEEN 5 AND 15
        AND ss.ss_coupon_amt > 1000
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, i_ss.i_category
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.s_state,
    agg.i_category,
    agg.total_store_sales,
    agg.total_store_returns,
    agg.total_catalog_sales,
    agg.total_web_returns,
    agg.total_net_profit,
    agg.avg_promo_cost,
    agg.distinct_tickets,
    (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS avg_net_profit_all,
    RANK() OVER (ORDER BY agg.total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 100
