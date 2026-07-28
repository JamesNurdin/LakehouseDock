WITH sales_2001 AS (
    SELECT
        d.d_year AS d_year,
        i.i_brand AS i_brand,
        i.i_brand_id AS i_brand_id,
        sm.sm_type AS sm_type,
        DATE_TRUNC('month', d.d_date) AS month,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS cnt_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand_id ORDER BY SUM(cs.cs_net_paid) DESC) AS brand_rank
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand_id IN (6008007, 8007005)
      AND sm.sm_type = 'AIR'
      AND t.t_am_pm = 'PM'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = cs.cs_promo_sk
            AND p.p_channel_email = 'Y'
      )
    GROUP BY d.d_year, i.i_brand, i.i_brand_id, sm.sm_type, DATE_TRUNC('month', d.d_date)
),
sales_2002 AS (
    SELECT
        d.d_year AS d_year,
        i.i_brand AS i_brand,
        i.i_brand_id AS i_brand_id,
        sm.sm_type AS sm_type,
        DATE_TRUNC('month', d.d_date) AS month,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS cnt_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand_id ORDER BY SUM(cs.cs_net_paid) DESC) AS brand_rank
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND i.i_brand_id = 7004003
      AND sm.sm_type = 'RAIL'
      AND t.t_am_pm = 'AM'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = cs.cs_promo_sk
            AND p.p_channel_press = 'N'
      )
    GROUP BY d.d_year, i.i_brand, i.i_brand_id, sm.sm_type, DATE_TRUNC('month', d.d_date)
)
SELECT *
FROM sales_2001
UNION ALL
SELECT *
FROM sales_2002
ORDER BY d_year, month, total_net_paid DESC
