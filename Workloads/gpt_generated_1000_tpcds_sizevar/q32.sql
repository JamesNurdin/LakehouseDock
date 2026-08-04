WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        cs_promo_sk,
        SUM(cs_ext_sales_price) AS total_sales_price,
        SUM(cs_ext_ship_cost) AS total_ship_cost,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_ext_ship_cost > 100
      AND cs_ship_addr_sk IN (2000933, 2121279)
      AND cs_net_paid_inc_ship BETWEEN 200 AND 2000
      AND cs_promo_sk IS NOT NULL
      AND cs_quantity > 0
    GROUP BY cs_item_sk, cs_order_number, cs_promo_sk
),
joined AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_ship_cost,
        cr.cr_catalog_page_sk,
        cr.cr_return_quantity,
        cr.cr_reversed_charge,
        s.cs_promo_sk,
        s.total_sales_price,
        s.total_ship_cost,
        s.total_net_profit,
        RANK() OVER (PARTITION BY cr.cr_item_sk ORDER BY cr.cr_return_amount DESC) AS return_amount_rank,
        CASE
            WHEN cr.cr_return_amount > 500 THEN 'High'
            WHEN cr.cr_return_amount > 200 THEN 'Medium'
            ELSE 'Low'
        END AS return_level,
        SUM(s.total_sales_price) OVER (
            PARTITION BY cr.cr_item_sk
            ORDER BY cr.cr_order_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_sales_price
    FROM catalog_returns cr
    JOIN sales_agg s
        ON cr.cr_item_sk = s.cs_item_sk
       AND cr.cr_order_number = s.cs_order_number
    WHERE cr.cr_return_ship_cost > 100
      AND cr.cr_catalog_page_sk IN (46, 125, 200)
      AND cr.cr_return_quantity BETWEEN 1 AND 10
      AND cr.cr_reversed_charge < 200
      AND cr.cr_return_amount IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cr.cr_order_number
            AND cr2.cr_return_amount > cr.cr_return_amount
            AND cr2.cr_item_sk <> cr.cr_item_sk
      )
)
SELECT
    cr_catalog_page_sk,
    cs_promo_sk,
    SUM(total_sales_price) AS sum_total_sales_price,
    AVG(total_ship_cost) AS avg_total_ship_cost,
    SUM(total_net_profit) AS sum_total_net_profit,
    COUNT(*) AS cnt_returns,
    MIN(return_amount_rank) AS best_return_rank,
    MAX(CASE WHEN return_level = 'High' THEN 1 ELSE 0 END) AS has_high_return,
    MAX(cumulative_sales_price) AS max_cumulative_sales_price
FROM joined
GROUP BY CUBE (cr_catalog_page_sk, cs_promo_sk)
ORDER BY sum_total_sales_price DESC
LIMIT 100
