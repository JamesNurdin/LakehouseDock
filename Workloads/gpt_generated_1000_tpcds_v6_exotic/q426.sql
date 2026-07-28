WITH sales_agg AS (
    SELECT
        cd_bill.cd_gender,
        i.i_category,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        AVG(p.p_cost) AS avg_promo_cost,
        MIN(cs.cs_sales_price) AS min_sales_price,
        MAX(cs.cs_sales_price) AS max_sales_price
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2450820
      AND i.i_class_id = 15
      AND p.p_discount_active = 'Y'
      AND cd_bill.cd_gender = 'M'
      AND hd_bill.hd_buy_potential = '5000+'
      AND ib.ib_upper_bound >= 50000
      AND wp.wp_link_count >= 10
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY GROUPING SETS (
        (cd_bill.cd_gender, i.i_category),
        (cd_bill.cd_gender),
        (i.i_category),
        ()
    )
)
SELECT
    cd_gender,
    i_category,
    total_net_paid,
    total_return_amt,
    distinct_orders,
    avg_promo_cost,
    min_sales_price,
    max_sales_price,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_net_paid DESC) AS category_rank,
    (
        SELECT AVG(distinct_total)
        FROM (
            SELECT DISTINCT total_net_paid AS distinct_total
            FROM sales_agg
        ) d
    ) AS overall_avg_net_paid
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
