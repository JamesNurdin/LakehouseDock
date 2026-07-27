WITH base AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_page_ids,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
        COUNT(DISTINCT cr.cr_order_number) AS num_catalog_returns,
        COUNT(DISTINCT wr.wr_order_number) AS num_web_returns
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_id,
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT
    c_customer_id,
    cd_gender,
    ib_lower_bound,
    ib_upper_bound,
    r_reason_desc,
    distinct_page_ids,
    total_sales,
    total_catalog_return_loss,
    total_web_return_loss,
    num_sales,
    num_catalog_returns,
    num_web_returns
FROM base
ORDER BY total_sales DESC
LIMIT 100
