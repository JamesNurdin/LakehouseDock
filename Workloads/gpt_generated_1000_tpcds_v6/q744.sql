WITH filtered_sales AS (
    SELECT ss.*
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450800 AND 2450900
      AND ss.ss_quantity > 1
      AND ss.ss_ext_sales_price > 100
),
joined_data AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        i.i_category,
        i.i_brand,
        c.c_birth_country,
        ca.ca_state,
        ca.ca_zip,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand,
        wr.wr_return_amt_inc_tax,
        wp.wp_type
    FROM filtered_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_brand = 'Brand#12'
      AND i.i_category = 'Electronics'
      AND c.c_birth_country = 'KAZAKHSTAN'
      AND ca.ca_state = 'CA'
      AND ca.ca_zip = '10069'
      AND inv.inv_quantity_on_hand >= 10
      AND (wr.wr_return_amt_inc_tax IS NULL OR wr.wr_return_amt_inc_tax > 200)
      AND EXISTS (
          SELECT 1 FROM inventory inv2
          WHERE inv2.inv_item_sk = i.i_item_sk
            AND inv2.inv_quantity_on_hand > 50
      )
),
agg AS (
    SELECT
        i_category,
        i_brand,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit) AS avg_profit,
        COUNT(DISTINCT ss_ticket_number) AS order_count,
        SUM(COALESCE(wr_return_amt_inc_tax, 0)) AS total_returns
    FROM joined_data
    GROUP BY ROLLUP (i_category, i_brand)
)
SELECT
    i_category,
    i_brand,
    CASE WHEN total_sales > 10000 THEN 'High' ELSE 'Low' END AS sales_level,
    total_sales,
    avg_profit,
    order_count,
    total_returns,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS rank_in_category
FROM agg
ORDER BY i_category, i_brand
