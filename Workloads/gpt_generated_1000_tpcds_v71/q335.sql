WITH sales_agg AS (
    SELECT
        cs.cs_order_number                 AS cs_order_number,
        cp.cp_department                  AS cp_department,
        cs.cs_sold_date_sk                AS cs_sold_date_sk,
        td.t_hour                         AS t_hour,
        ca.ca_state                       AS ca_state,
        cd.cd_gender                      AS cd_gender,
        hd.hd_income_band_sk              AS hd_income_band_sk,
        SUM(cs.cs_net_paid)               AS total_net_paid,
        COUNT(DISTINCT cs.cs_item_sk)     AS distinct_items,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_return_qty,
        COALESCE(SUM(cr.cr_return_amount), 0)   AS total_return_amount,
        MIN(r.r_reason_desc)              AS first_return_reason
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451170               -- filter 1 (date surrogate range)
      AND cs.cs_quantity > 1                                          -- filter 2 (quantity)
      AND cp.cp_department = 'Sports'                                 -- filter 3 (department)
      AND td.t_hour BETWEEN 9 AND 17                                   -- filter 4 (business hours)
      AND ca.ca_state = 'CA'                                           -- filter 5 (address state)
      AND cd.cd_gender = 'M'                                           -- filter 6 (gender)
      AND hd.hd_income_band_sk = 5                                     -- filter 7 (income band)
    GROUP BY cs.cs_order_number, cp.cp_department, cs.cs_sold_date_sk, td.t_hour, ca.ca_state, cd.cd_gender, hd.hd_income_band_sk
)
SELECT
    sa.cp_department,
    COUNT(*)                               AS order_cnt,
    AVG(sa.total_net_paid)                AS avg_net_paid,
    SUM(sa.total_return_amount)           AS sum_return_amount
FROM sales_agg sa
WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN web_page wp
          ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE wr.wr_order_number = sa.cs_order_number
          AND wp.wp_type = 'Home'
    )
  AND EXISTS (
        SELECT 1
        FROM store_sales ss
        JOIN time_dim td2
          ON ss.ss_sold_time_sk = td2.t_time_sk
        JOIN customer c
          ON ss.ss_customer_sk = c.c_customer_sk
        WHERE td2.t_hour = sa.t_hour
          AND c.c_customer_id = '000000001'
    )
GROUP BY sa.cp_department
HAVING AVG(sa.total_net_paid) > 500
ORDER BY avg_net_paid DESC
LIMIT 100
