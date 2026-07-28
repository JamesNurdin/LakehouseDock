WITH base AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        c.c_customer_id,
        cc.cc_name AS call_center_name,
        SUM(cs.cs_net_paid) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_quantity) AS total_quantity,
        -- subquery for average net paid of the same item across all sales
        (SELECT AVG(cs2.cs_net_paid)
         FROM catalog_sales cs2
         WHERE cs2.cs_item_sk = cs.cs_item_sk) AS avg_item_sales,
        -- flag for sales category using CASE WHEN
        CASE
            WHEN SUM(cs.cs_net_paid) > (SELECT AVG(cs2.cs_net_paid)
                                         FROM catalog_sales cs2
                                         WHERE cs2.cs_item_sk = cs.cs_item_sk) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS sales_category
    FROM catalog_sales cs
    INNER JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN store_sales ss
        ON i.i_item_sk = ss.ss_item_sk
    INNER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand_id IN (2002002, 3002001)
      AND c.c_birth_year BETWEEN 1950 AND 1965
      AND p.p_discount_active = 'Y'
      AND ib.ib_upper_bound > 50000
      AND cs.cs_quantity > 5
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        c.c_customer_id,
        cc.cc_name,
        ib.ib_upper_bound,
        p.p_discount_active,
        cs.cs_item_sk
), ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank_year,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS overall_row_num
    FROM base
)
SELECT
    i_item_id,
    i_product_name,
    d_year,
    c_customer_id,
    call_center_name,
    total_sales,
    order_cnt,
    total_quantity,
    sales_category,
    sales_rank_year,
    overall_row_num
FROM ranked
ORDER BY total_sales DESC
LIMIT 100
