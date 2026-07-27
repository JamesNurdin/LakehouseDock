WITH
    promo_distinct AS (
        SELECT DISTINCT p.p_promo_sk,
                        p.p_promo_name
        FROM promotion p
        WHERE p.p_discount_active = 'Y'
    ),
    hd_income AS (
        SELECT hd.hd_demo_sk,
               ib.ib_income_band_sk,
               ib.ib_lower_bound,
               ib.ib_upper_bound
        FROM household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ib.ib_lower_bound >= 50000
    )
SELECT
    channel,
    promo_name,
    year,
    orders,
    sales_amount,
    returns_amount,
    net_sales
FROM (
    -- Catalog channel (catalog sales + catalog returns)
    SELECT
        'Catalog' AS channel,
        pd.p_promo_name AS promo_name,
        d.d_year AS year,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        COALESCE(SUM(cr.cr_return_amount), 0) AS returns_amount,
        SUM(cs.cs_ext_sales_price) - COALESCE(SUM(cr.cr_return_amount), 0) AS net_sales
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promo_distinct pd ON cs.cs_promo_sk = pd.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN hd_income hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Electronics'
      AND sm.sm_type = 'AIR'
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          JOIN date_dim dwp ON wp.wp_creation_date_sk = dwp.d_date_sk
          WHERE wp.wp_customer_sk = c.c_customer_sk
            AND wp.wp_type = 'Home'
            AND dwp.d_year = 2001
      )
    GROUP BY cp.cp_department, pd.p_promo_name, d.d_year

    UNION ALL

    -- Store & Web channel (store sales + store returns + web returns)
    SELECT
        'Store/Web' AS channel,
        pd.p_promo_name AS promo_name,
        d_s.d_year AS year,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        COALESCE(SUM(sr.sr_return_amt), 0) + COALESCE(SUM(wr.wr_return_amt), 0) AS returns_amount,
        SUM(ss.ss_ext_sales_price) - (COALESCE(SUM(sr.sr_return_amt), 0) + COALESCE(SUM(wr.wr_return_amt), 0)) AS net_sales
    FROM store_sales ss
    JOIN promo_distinct pd ON ss.ss_promo_sk = pd.p_promo_sk
    JOIN date_dim d_s ON ss.ss_sold_date_sk = d_s.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN hd_income hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_s.d_date_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
    WHERE d_s.d_year = 2001
      AND r_sr.r_reason_desc = 'Not working any more'
      AND wp.wp_type = 'Product'
      AND d_wp.d_year = 2001
    GROUP BY pd.p_promo_name, d_s.d_year
) AS final_result
ORDER BY net_sales DESC
LIMIT 100
