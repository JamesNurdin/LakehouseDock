WITH sales_return_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        hd.hd_income_band_sk,
        cp.cp_department,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        COUNT(DISTINCT cr.cr_order_number) AS return_transactions
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        s.s_state = 'CA'
        AND s.s_company_id = 1
        AND hd.hd_income_band_sk BETWEEN 3 AND 10
        AND hd.hd_vehicle_count >= 1
        AND cp.cp_type = 'PROMO'
        AND cr.cr_return_tax > 5.00
        AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY
        s.s_store_id,
        s.s_state,
        hd.hd_income_band_sk,
        cp.cp_department
)
SELECT
    s_store_id AS store_id,
    s_state AS state,
    AVG(total_net_loss) AS avg_net_loss,
    SUM(total_sales) AS sum_sales,
    SUM(total_returns) AS sum_returns
FROM sales_return_agg
GROUP BY s_store_id, s_state
HAVING AVG(total_net_loss) > 1000
ORDER BY avg_net_loss DESC
LIMIT 100
