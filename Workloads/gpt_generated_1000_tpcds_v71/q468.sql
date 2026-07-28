WITH ss_join AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        d.d_year,
        i.i_category AS item_category,
        s.s_store_name AS store_name,
        p.p_discount_active,
        cd.cd_gender
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2022
      AND NOT EXISTS (
          SELECT 1
          FROM promotion p_ex
          WHERE p_ex.p_promo_sk = ss.ss_promo_sk
            AND p_ex.p_discount_active = 'Y'
      )
)
SELECT
    ss_join.store_name,
    ss_join.item_category,
    COUNT(DISTINCT ss_join.ss_item_sk) AS distinct_items_sold,
    SUM(ss_join.ss_quantity) AS total_quantity,
    AVG(ss_join.ss_net_profit) AS avg_net_profit,
    (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_sold_date_sk = (
            SELECT d_sub.d_date_sk
            FROM date_dim d_sub
            WHERE d_sub.d_year = 2022
            LIMIT 1
        )
    ) AS overall_avg_net_profit
FROM ss_join
JOIN catalog_sales cs ON cs.cs_sold_date_sk = ss_join.ss_sold_date_sk
JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p2 ON cs.cs_promo_sk = p2.p_promo_sk
JOIN item i2 ON cs.cs_item_sk = i2.i_item_sk
JOIN customer_demographics cd2 ON cs.cs_bill_cdemo_sk = cd2.cd_demo_sk
GROUP BY
    ss_join.store_name,
    ss_join.item_category
ORDER BY avg_net_profit DESC
LIMIT 100
