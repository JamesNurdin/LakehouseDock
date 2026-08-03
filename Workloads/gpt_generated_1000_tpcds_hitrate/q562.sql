WITH rs_agg AS (
    SELECT
        sr_item_sk,
        sr_returned_date_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_item_sk, sr_returned_date_sk
),
sales_agg AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        d.d_date,
        t.t_hour,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        cd.cd_gender,
        p.p_promo_name,
        p.p_discount_active,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        MIN(ss.ss_sales_price) AS min_price,
        MAX(ss.ss_sales_price) AS max_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND cd.cd_credit_rating = 'Good'
      AND ss.ss_sold_date_sk <= (
          SELECT MAX(d2.d_date_sk)
          FROM date_dim d2
          WHERE d2.d_year = 2001
      )
      AND EXISTS (
          SELECT 1
          FROM store_returns r
          WHERE r.sr_ticket_number = ss.ss_ticket_number
            AND r.sr_return_quantity > 0
      )
    GROUP BY
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        d.d_date,
        t.t_hour,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        cd.cd_gender,
        p.p_promo_name,
        p.p_discount_active
)
SELECT
    sa.ss_ticket_number,
    sa.d_date,
    sa.t_hour,
    sa.i_product_name,
    sa.i_brand,
    sa.cd_gender,
    sa.p_promo_name,
    CASE WHEN sa.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    rs.total_return_amt,
    rs.return_cnt,
    sa.total_net_paid,
    sa.avg_discount,
    sa.min_price,
    sa.max_price,
    sa.distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY sa.i_category ORDER BY sa.total_net_paid DESC) AS category_rank
FROM sales_agg sa
LEFT JOIN rs_agg rs
    ON rs.sr_item_sk = sa.i_item_sk
   AND rs.sr_returned_date_sk = sa.ss_sold_date_sk
ORDER BY sa.total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
