WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        p.p_discount_active,
        cc.cc_state,
        cs.cs_order_number,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        wp.wp_image_count,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN web_page wp
        ON c.c_customer_sk = wp.wp_customer_sk
    LEFT JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
        AND wp.wp_web_page_sk = wr.wr_web_page_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_brand = 'BrandX'
      AND p.p_discount_active = 'Y'
      AND ib.ib_upper_bound > 50000
),
intersect_set AS (
    SELECT c_customer_sk FROM customer WHERE c_birth_year < 1980
    INTERSECT
    SELECT ss_customer_sk AS c_customer_sk FROM store_sales WHERE ss_quantity > 2
),
union_set AS (
    SELECT c_customer_sk FROM base WHERE cr_return_quantity IS NOT NULL
    UNION
    SELECT c_customer_sk FROM base WHERE wr_return_quantity IS NOT NULL
),
except_set AS (
    SELECT c_customer_sk FROM base WHERE p_discount_active = 'Y'
    EXCEPT
    SELECT c_customer_sk FROM base WHERE i_brand = 'OtherBrand'
)
SELECT
    b.c_customer_sk,
    b.c_first_name,
    b.c_last_name,
    b.i_brand,
    b.i_category,
    b.ss_net_paid,
    b.cs_net_paid,
    (b.ss_net_paid + b.cs_net_paid) AS total_net_paid,
    RANK() OVER (PARTITION BY b.i_brand ORDER BY (b.ss_net_paid + b.cs_net_paid) DESC) AS brand_customer_rank,
    CASE
        WHEN b.cr_return_quantity > 0 THEN 'Catalog Return'
        WHEN b.wr_return_quantity > 0 THEN 'Web Return'
        ELSE 'No Return'
    END AS return_type
FROM base b
WHERE b.c_customer_sk IN (SELECT c_customer_sk FROM intersect_set)
  AND b.c_customer_sk IN (SELECT c_customer_sk FROM union_set)
  AND b.c_customer_sk NOT IN (SELECT c_customer_sk FROM except_set)
  AND EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_customer_sk = b.c_customer_sk
          AND wp2.wp_image_count > 3
    )
ORDER BY brand_customer_rank
LIMIT 100
