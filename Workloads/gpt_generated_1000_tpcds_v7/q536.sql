WITH sales_agg AS (
    SELECT
        ca.ca_state,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE i.i_category_id IN (6, 7, 8, 9)
      AND i.i_units = 'Dozen'
      AND ca.ca_gmt_offset >= -5.00
      AND ss.ss_ext_list_price > 500
      AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY ca.ca_state, i.i_category
)
SELECT
    ca_state,
    i_category,
    total_sales,
    sales_cnt,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS rank_within_state
FROM sales_agg
ORDER BY ca_state, rank_within_state
