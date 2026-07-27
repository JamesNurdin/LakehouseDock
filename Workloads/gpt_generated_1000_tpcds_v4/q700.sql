WITH returns_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.r_reason_desc,
        sm.sm_type,
        wp.wp_type,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT cr.cr_order_number) AS cnt_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS cnt_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS cnt_web_sales
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_cdemo_sk = cd.cd_demo_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
        AND ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ca.ca_gmt_offset >= -6
      AND ib.ib_lower_bound >= 100000
      AND r.r_reason_desc LIKE '%damaged%'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.r_reason_desc,
        sm.sm_type,
        wp.wp_type
)
SELECT
    rs.r_reason_desc,
    rs.sm_type,
    rs.wp_type,
    rs.total_net_loss,
    rs.total_store_profit,
    rs.total_web_profit,
    rs.cnt_returns,
    rs.cnt_store_sales,
    rs.cnt_web_sales,
    ROW_NUMBER() OVER (PARTITION BY rs.r_reason_desc ORDER BY rs.total_net_loss DESC) AS loss_rank
FROM returns_sales rs
WHERE rs.total_store_profit > 0
ORDER BY rs.total_net_loss DESC
LIMIT 100
