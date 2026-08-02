WITH base AS (
    SELECT
        s.s_store_name,
        i.i_product_name,
        ss.ss_ext_sales_price,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        ss.ss_ticket_number
    FROM store_sales ss
    INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    INNER JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    FULL OUTER JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN household_demographics hd_cr_ref ON cr.cr_refunded_hdemo_sk = hd_cr_ref.hd_demo_sk
    LEFT JOIN household_demographics hd_cr_ret ON cr.cr_returning_hdemo_sk = hd_cr_ret.hd_demo_sk
    LEFT JOIN customer_address ca_cr_ref ON cr.cr_refunded_addr_sk = ca_cr_ref.ca_address_sk
    LEFT JOIN customer_address ca_cr_ret ON cr.cr_returning_addr_sk = ca_cr_ret.ca_address_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN household_demographics hd_wr_ref ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
    LEFT JOIN household_demographics hd_wr_ret ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
    LEFT JOIN customer_address ca_wr_ref ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
    LEFT JOIN customer_address ca_wr_ret ON wr.wr_returning_addr_sk = ca_wr_ret.ca_address_sk
), aggregated AS (
    SELECT
        s_store_name,
        i_product_name,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_store_return_qty,
        SUM(COALESCE(cr_return_quantity, 0)) AS total_catalog_return_qty,
        SUM(COALESCE(wr_return_quantity, 0)) AS total_web_return_qty,
        SUM(COALESCE(sr_net_loss, 0)) + SUM(COALESCE(cr_net_loss, 0)) + SUM(COALESCE(wr_net_loss, 0)) AS total_net_loss,
        COUNT(DISTINCT ss_ticket_number) AS sales_transactions
    FROM base
    GROUP BY s_store_name, i_product_name
)
SELECT
    s_store_name,
    i_product_name,
    total_sales,
    total_store_return_qty,
    total_catalog_return_qty,
    total_web_return_qty,
    total_net_loss,
    sales_transactions,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
