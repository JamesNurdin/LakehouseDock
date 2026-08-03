WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_item_sk,
        i.i_item_desc,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_refunded_cash, 0)) AS total_refunds,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_class = 'fragrances'
      AND s.s_state = 'CA'
      AND ca.ca_country = 'United States'
      AND cd.cd_gender = 'M'
      AND ib.ib_lower_bound >= 50000
      AND s.s_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
    GROUP BY s.s_store_sk, s.s_store_name, i.i_item_sk, i.i_item_desc
),
web_agg AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        i.i_item_sk,
        i.i_item_desc,
        SUM(wr.wr_return_amt) AS total_web_returns,
        COUNT(DISTINCT wr.wr_order_number) AS num_web_returns
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_class = 'fragrances'
      AND c.c_birth_country = 'United States'
      AND cd.cd_gender = 'M'
      AND ib.ib_upper_bound <= 150000
      AND wp.wp_type = 'product'
    GROUP BY wp.wp_web_page_sk, wp.wp_type, i.i_item_sk, i.i_item_desc
),
combined AS (
    SELECT
        s.s_store_name,
        i.i_item_desc,
        sa.total_sales,
        sa.total_refunds,
        wa.total_web_returns,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY sa.total_sales DESC) AS rn
    FROM sales_agg sa
    JOIN store s ON sa.s_store_sk = s.s_store_sk
    JOIN item i ON sa.i_item_sk = i.i_item_sk
    LEFT JOIN web_agg wa ON i.i_item_sk = wa.i_item_sk
    CROSS JOIN (VALUES (1), (2)) AS t(multiplier)
    WHERE (sa.total_sales * t.multiplier) > 1000
)
SELECT final.s_store_name,
       final.i_item_desc,
       final.total_sales,
       final.total_refunds,
       final.total_web_returns,
       final.rn
FROM (
    SELECT s_store_name, i_item_desc, total_sales, total_refunds, total_web_returns, rn
    FROM combined
    WHERE rn = 1
    UNION DISTINCT
    SELECT s_store_name, i_item_desc, total_sales, total_refunds, total_web_returns, rn
    FROM combined
    WHERE total_web_returns IS NOT NULL
) AS final
WHERE final.total_sales > (
    SELECT AVG(total_sales) FROM combined
)
ORDER BY final.total_sales DESC, final.s_store_name
