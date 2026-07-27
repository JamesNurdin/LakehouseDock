WITH sales_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        SUM(wr.wr_net_loss) AS total_returns_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_returns,
        -- scalar subquery: overall average net loss across all web returns
        (SELECT AVG(wr_all.wr_net_loss) FROM web_returns wr_all) AS overall_avg_loss
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        cd.cd_education_status IN ('College', 'Advanced Degree')
        AND cd.cd_marital_status = 'M'
        AND ib.ib_lower_bound >= 30000
        AND s.s_state = 'CA'
        AND ca.ca_country = 'United States'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    HAVING
        SUM(ss.ss_net_paid_inc_tax) > 10000
)
SELECT
    sr.s_store_id,
    sr.s_store_name,
    sr.ib_lower_bound,
    sr.ib_upper_bound,
    sr.total_sales,
    sr.total_returns_loss,
    (sr.total_sales - sr.total_returns_loss) / NULLIF(sr.total_sales, 0) AS sales_net_ratio,
    sr.distinct_tickets,
    sr.distinct_returns,
    sr.overall_avg_loss
FROM sales_returns sr
WHERE sr.total_returns_loss IS NOT NULL
ORDER BY sales_net_ratio DESC
LIMIT 100
