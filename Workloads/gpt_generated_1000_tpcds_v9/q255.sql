/*
Goal: Identify top stores in California by total combined profit from store and catalog sales, ranking them within the state and overall, while ensuring each store has at least one catalog return.
*/
WITH base AS (
    SELECT
        s.s_store_name,
        s.s_state,
        s.s_tax_percentage,
        cc.cc_manager,
        cp.cp_type,
        ca.ca_state AS customer_state,
        cd.cd_gender,
        r.r_reason_desc,
        ss.ss_ticket_number,
        ss.ss_net_profit AS ss_net_profit,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_order_number,
        cr.cr_return_quantity,
        sr.sr_return_quantity,
        wr.wr_return_quantity,
        wp.wp_max_ad_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
                           AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN web_returns wr ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
                          AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason reason_web ON wr.wr_reason_sk = reason_web.r_reason_sk
    WHERE s.s_state = 'CA'
      AND cc.cc_manager = 'John Melendez'
      AND wp.wp_max_ad_count >= 2
      AND cp.cp_type = 'A'
      AND s.s_tax_percentage > 0.05
      AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
              AND cr2.cr_return_quantity > 0
          )
),
agg AS (
    SELECT
        s_store_name,
        s_state,
        cc_manager,
        cp_type,
        customer_state,
        cd_gender,
        r_reason_desc,
        SUM(ss_net_profit) AS total_store_sales_profit,
        SUM(cs_net_profit) AS total_catalog_sales_profit,
        SUM(ss_net_profit + cs_net_profit) AS total_combined_profit,
        s_tax_percentage,
        wp_max_ad_count
    FROM base
    GROUP BY
        s_store_name,
        s_state,
        cc_manager,
        cp_type,
        customer_state,
        cd_gender,
        r_reason_desc,
        s_tax_percentage,
        wp_max_ad_count
)
SELECT
    s_store_name,
    s_state,
    cc_manager,
    cp_type,
    customer_state,
    cd_gender,
    r_reason_desc,
    total_store_sales_profit,
    total_catalog_sales_profit,
    total_combined_profit,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_combined_profit DESC) AS profit_rank_state,
    DENSE_RANK() OVER (ORDER BY total_combined_profit DESC) AS overall_profit_rank
FROM agg
ORDER BY total_combined_profit DESC
LIMIT 100
