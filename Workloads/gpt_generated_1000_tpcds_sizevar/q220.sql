WITH sales_agg AS (
    SELECT
        p.p_promo_id,
        cp.cp_department,
        SUM(cs.cs_net_paid_inc_ship) AS total_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr ON d.d_date_sk = wr.wr_returned_date_sk
    WHERE d.d_fy_year = 1910
      AND p.p_channel_event = 'N'
      AND cp.cp_department = 'Books'
      AND c.c_preferred_cust_flag = 'Y'
      AND cd.cd_gender = 'M'
      AND p.p_promo_id IN (
          SELECT p_promo_id FROM promotion WHERE p_discount_active = 'Y'
      )
    GROUP BY p.p_promo_id, cp.cp_department
),
ranked AS (
    SELECT
        p_promo_id,
        cp_department,
        total_paid,
        order_cnt,
        ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_paid DESC) AS rnk
    FROM sales_agg
)
SELECT
    p_promo_id,
    cp_department,
    total_paid,
    order_cnt,
    rnk
FROM ranked
WHERE rnk <= 3
ORDER BY total_paid DESC
OFFSET 0 LIMIT 100
