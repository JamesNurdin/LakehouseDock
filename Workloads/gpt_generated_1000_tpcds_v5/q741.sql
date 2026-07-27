WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_sales_price,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_year,
        s.s_store_name,
        s.s_state,
        ca.ca_state,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        cp.cp_department,
        cp.cp_catalog_page_sk,
        cp.cp_type,
        wp.wp_type
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND ca.ca_state = 'CA'
      AND hd.hd_buy_potential = '>10000'
      AND hd.hd_vehicle_count >= 1
      AND cp.cp_department = 'Books'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp2
          WHERE cp2.cp_catalog_page_sk = cp.cp_catalog_page_sk
            AND cp2.cp_type = 'A'
      )
)
SELECT
    s_store_name,
    d_year,
    cp_department,
    COUNT(DISTINCT ss_ticket_number) AS transaction_count,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_ext_discount_amt) AS avg_discount,
    MIN(ss_sales_price) AS min_price,
    MAX(ss_sales_price) AS max_price,
    (
        SELECT MAX(hd_income_band_sk)
        FROM household_demographics
        WHERE hd_buy_potential = 'Unknown'
    ) AS max_income_band_unknown
FROM filtered_sales
GROUP BY s_store_name, d_year, cp_department
ORDER BY total_sales DESC
LIMIT 100
