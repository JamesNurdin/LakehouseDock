WITH ss_base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        s.s_store_id,
        d.d_year
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
)
SELECT
    sb.s_store_id,
    sb.d_year,
    SUM(sb.ss_net_paid) AS total_store_sales,
    SUM(sb.ss_net_profit) AS total_store_profit,
    COUNT(DISTINCT sb.ss_ticket_number) AS sales_transactions,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_return_loss,
    COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_return_loss
FROM ss_base sb
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = sb.ss_ticket_number
   AND sr.sr_item_sk = sb.ss_item_sk
   AND sr.sr_store_sk = sb.ss_store_sk
LEFT JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN time_dim t_sr
    ON sr.sr_return_time_sk = t_sr.t_time_sk
LEFT JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
LEFT JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = sb.ss_sold_date_sk
LEFT JOIN date_dim d_cs
    ON cs.cs_sold_date_sk = d_cs.d_date_sk
LEFT JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
LEFT JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
LEFT JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
LEFT JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = sb.ss_item_sk
LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
GROUP BY sb.s_store_id, sb.d_year
ORDER BY total_store_sales DESC
LIMIT 100
