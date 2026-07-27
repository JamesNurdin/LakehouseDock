WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        i.i_brand,
        i.i_category,
        d_sold.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(cs.cs_net_paid) DESC) AS brand_rank
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    WHERE d_sold.d_year = 2001
      AND i.i_brand = 'Brand#45'
      AND sm.sm_carrier = 'DHL'
      AND cc.cc_state = 'CA'
      AND ib.ib_upper_bound > 50000
    GROUP BY cs.cs_item_sk, i.i_brand, i.i_category, d_sold.d_year
)
SELECT
    sa.i_brand,
    sa.i_category,
    AVG(sa.total_net_paid) AS avg_net_paid,
    COUNT(*) AS num_items,
    MAX(sa.brand_rank) AS max_brand_rank
FROM sales_agg sa
WHERE EXISTS (
        SELECT 1
        FROM store s
        JOIN date_dim d_store
            ON s.s_closed_date_sk = d_store.d_date_sk
        WHERE d_store.d_year = sa.d_year
          AND s.s_state = 'CA'
    )
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        JOIN date_dim d_wp
            ON wp.wp_creation_date_sk = d_wp.d_date_sk
        WHERE d_wp.d_year = sa.d_year
          AND wp.wp_type = 'content'
    )
  AND EXISTS (
        SELECT 1
        FROM web_site ws
        JOIN date_dim d_ws
            ON ws.web_open_date_sk = d_ws.d_date_sk
        WHERE d_ws.d_year = sa.d_year
          AND ws.web_name = 'SiteA'
    )
GROUP BY sa.i_brand, sa.i_category
HAVING AVG(sa.total_net_paid) > 1000
ORDER BY avg_net_paid DESC
LIMIT 100
