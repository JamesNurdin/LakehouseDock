WITH joined_all AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        i.i_item_id,
        i.i_product_name,
        i.i_category_id,
        i.i_current_price,
        p.p_promo_name,
        p.p_discount_active,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        cp.cp_department,
        sr.sr_return_amt,
        wp.wp_url,
        -- analytic placeholders (will be computed in outer query)
        cs.cs_sold_date_sk AS sales_date_key
    FROM catalog_sales cs
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p                    ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                    ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss                ON ss.ss_item_sk = i.i_item_sk
                                         AND ss.ss_cdemo_sk = cd.cd_demo_sk
                                         AND ss.ss_hdemo_sk = hd.hd_demo_sk
                                         AND ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr              ON sr.sr_ticket_number = ss.ss_ticket_number
                                         AND sr.sr_item_sk = i.i_item_sk
    JOIN web_returns wr                ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp                   ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_purchase_estimate >= 5000
      AND i.i_category_id = 8
      AND p.p_discount_active = 'Y'
      AND ib.ib_upper_bound <= 150000
),
high_sales_items AS (
    SELECT DISTINCT i_item_id
    FROM joined_all
    WHERE cs_ext_sales_price > 5000
),
returned_items AS (
    SELECT DISTINCT i_item_id
    FROM joined_all
    WHERE sr_return_amt > 0
),
items_without_returns AS (
    SELECT i_item_id FROM high_sales_items
    EXCEPT
    SELECT i_item_id FROM returned_items
)
SELECT
    ja.cs_sold_date_sk,
    ja.i_item_id,
    ja.i_product_name,
    ja.i_category_id,
    ja.p_promo_name,
    ja.cd_gender,
    ja.cd_purchase_estimate,
    ja.hd_buy_potential,
    ja.ib_lower_bound,
    ja.cs_ext_sales_price AS sales_amount,
    ja.sr_return_amt AS return_amount,
    ja.wp_url,
    LAG(ja.cs_sales_price) OVER (PARTITION BY ja.i_category_id ORDER BY ja.sales_date_key) AS prev_sales_price,
    ROW_NUMBER() OVER (PARTITION BY ja.i_category_id ORDER BY ja.cs_net_paid DESC) AS category_sales_rank,
    ROW_NUMBER() OVER (ORDER BY ja.cs_net_paid DESC) AS global_rank,
    SUM(ja.cs_ext_sales_price) OVER (PARTITION BY ja.i_category_id ORDER BY ja.sales_date_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM joined_all ja
JOIN items_without_returns iwr ON ja.i_item_id = iwr.i_item_id
ORDER BY global_rank
LIMIT 100
