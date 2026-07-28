WITH base AS (
    SELECT
        s.s_state,
        cp.cp_type,
        cd.cd_gender,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(wr.wr_return_amt) AS total_web_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        SUM(p.p_cost) AS total_promo_cost
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason reason_sr
        ON sr.sr_reason_sk = reason_sr.r_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason reason_cr
        ON cr.cr_reason_sk = reason_cr.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN reason reason_wr
        ON wr.wr_reason_sk = reason_wr.r_reason_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_catalog_number BETWEEN 10 AND 20
      AND p.p_channel_radio = 'N'
      AND ca.ca_country = 'United States'
      AND s.s_state = 'CA'
    GROUP BY ROLLUP (s.s_state, cp.cp_type, cd.cd_gender)
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    s_state,
    cp_type,
    cd_gender,
    total_sales,
    total_store_returns,
    total_catalog_returns,
    total_web_returns,
    orders,
    total_promo_cost,
    SUM(total_sales) OVER (PARTITION BY s_state ORDER BY cp_type ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales_by_state
FROM base
ORDER BY s_state, cp_type, cd_gender
LIMIT 100
