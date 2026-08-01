WITH
catalog_returns_summary AS (
    SELECT
        cr_item_sk,
        cr_reason_sk,
        COUNT(*) AS cnt_returns,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
    WHERE cr_return_amount > 10.00
    GROUP BY cr_item_sk, cr_reason_sk
),
inventory_summary AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk
),
sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_class,
        d.d_year,
        c.c_customer_id,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_type,
        ca.ca_state,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Electronics'
      AND sm.sm_type = 'AIR'
      AND ca.ca_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND ib.ib_lower_bound >= 50000
      AND EXISTS (
          SELECT 1 FROM catalog_returns cr2
          WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
            AND cr2.cr_return_amount > 20.00
      )
    GROUP BY
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_class,
        d.d_year,
        c.c_customer_id,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_type,
        ca.ca_state
)
SELECT
    sa.i_item_id,
    sa.i_product_name,
    sa.i_category,
    sa.i_class,
    sa.d_year,
    sa.c_customer_id,
    sa.hd_income_band_sk,
    sa.ib_lower_bound,
    sa.ib_upper_bound,
    sa.sm_type,
    sa.ca_state,
    sa.total_sales,
    sa.total_discount,
    sa.total_profit,
    sa.distinct_orders,
    crs.cnt_returns,
    crs.total_return_amount,
    inv_s.total_on_hand,
    r.r_reason_desc,
    s.s_store_name,
    wp.wp_url,
    ROW_NUMBER() OVER (PARTITION BY sa.i_category ORDER BY sa.total_sales DESC) AS category_sales_rank,
    (SELECT MAX(inv2.total_on_hand) FROM inventory_summary inv2 WHERE inv2.inv_item_sk = sa.i_item_sk) AS max_on_hand_for_item
FROM sales_agg sa
LEFT JOIN catalog_returns_summary crs ON crs.cr_item_sk = sa.i_item_sk
LEFT JOIN reason r ON crs.cr_reason_sk = r.r_reason_sk
LEFT JOIN inventory_summary inv_s ON inv_s.inv_item_sk = sa.i_item_sk
-- Join to a date dimension row so we can connect the store table via its closed‑date key
LEFT JOIN date_dim d_store ON d_store.d_date_sk = sa.sold_date_sk
LEFT JOIN store s ON s.s_closed_date_sk = d_store.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = sa.i_item_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN date_dim d_wp_access ON d_wp_access.d_date_sk = wp.wp_access_date_sk
WHERE
    inv_s.total_on_hand > 100
    AND (r.r_reason_desc IS NULL OR r.r_reason_desc LIKE '%damaged%')
ORDER BY
    sa.total_sales DESC,
    sa.i_item_id
LIMIT 100
