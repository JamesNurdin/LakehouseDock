WITH promo_avg AS (
    SELECT avg(p_cost) AS avg_cost
    FROM promotion
    WHERE p_discount_active = 'Y'
),
joined_data AS (
    SELECT
        i_sales.i_item_id,
        i_sales.i_product_name,
        i_sales.i_brand,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(inv1.inv_quantity_on_hand) AS inventory_qty,
        SUM(wr.wr_return_amt) AS total_return_amt,
        p_main.p_promo_id,
        p_main.p_cost,
        p_item.p_promo_id AS return_promo_id,
        i_returns.i_item_desc
    FROM store_sales ss
    JOIN item i_sales
        ON ss.ss_item_sk = i_sales.i_item_sk                                   -- join 1
    JOIN promotion p_main
        ON ss.ss_promo_sk = p_main.p_promo_sk                                 -- join 2
    JOIN item i_promo_item
        ON p_main.p_item_sk = i_promo_item.i_item_sk                          -- join 3
    JOIN inventory inv1
        ON i_sales.i_item_sk = inv1.inv_item_sk                               -- join 4
    JOIN inventory inv2
        ON i_promo_item.i_item_sk = inv2.inv_item_sk                           -- join 5
    JOIN promotion p_item
        ON i_sales.i_item_sk = p_item.p_item_sk                               -- join 6
    JOIN web_returns wr
        ON wr.wr_item_sk = i_sales.i_item_sk                                   -- join 7
    JOIN item i_returns
        ON wr.wr_item_sk = i_returns.i_item_sk                                 -- join 8
    JOIN inventory inv3
        ON i_returns.i_item_sk = inv3.inv_item_sk                              -- join 9
    JOIN promotion p_extra
        ON i_sales.i_item_sk = p_extra.p_item_sk                               -- join 10
    WHERE p_main.p_cost > (SELECT avg_cost FROM promo_avg)
      AND wr.wr_reason_sk IN (16, 33, 58)
    GROUP BY
        i_sales.i_item_id,
        i_sales.i_product_name,
        i_sales.i_brand,
        p_main.p_promo_id,
        p_main.p_cost,
        p_item.p_promo_id,
        i_returns.i_item_desc
)
SELECT DISTINCT
    jd.i_item_id,
    jd.i_product_name,
    jd.i_brand,
    jd.total_sales,
    jd.total_profit,
    jd.inventory_qty,
    jd.total_return_amt,
    jd.p_promo_id,
    jd.p_cost,
    jd.return_promo_id,
    jd.i_item_desc,
    RANK() OVER (PARTITION BY jd.i_brand ORDER BY jd.total_sales DESC) AS brand_sales_rank,
    SUM(jd.total_sales) OVER (PARTITION BY jd.i_brand ORDER BY jd.total_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS brand_cumulative_sales
FROM joined_data jd
ORDER BY jd.total_sales DESC
LIMIT 100
