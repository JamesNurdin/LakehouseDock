WITH base AS (
    SELECT
        cp.cp_department,
        wp.wp_type,
        cr.cr_return_amount,
        cr.cr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss,
        ca_refund.ca_country
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c_refund
        ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_refund_web
        ON wr.wr_refunded_customer_sk = c_refund_web.c_customer_sk
    JOIN customer_address ca_refund_web
        ON wr.wr_refunded_addr_sk = ca_refund_web.ca_address_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Books'
      AND ca_refund.ca_country = 'United States'
),
agg AS (
    SELECT
        cp_department,
        wp_type,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(wr_return_amt) AS total_web_return_amount,
        SUM(cr_net_loss + wr_net_loss) AS total_combined_net_loss
    FROM base
    GROUP BY cp_department, wp_type
)
SELECT
    cp_department,
    wp_type,
    total_catalog_return_amount,
    total_web_return_amount,
    total_combined_net_loss,
    AVG(total_catalog_return_amount + total_web_return_amount) OVER (PARTITION BY cp_department ORDER BY wp_type) AS avg_return_by_dept,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_combined_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_combined_net_loss DESC
LIMIT 20
