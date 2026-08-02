WITH sales AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_bill_customer_sk AS bill_customer_sk,
        cs.cs_ship_customer_sk AS ship_customer_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_sales_price AS sales_amount,
        CAST(NULL AS decimal(7,2)) AS return_amount,
        cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
returns AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        CAST(NULL AS integer) AS call_center_sk,
        sr.sr_customer_sk AS bill_customer_sk,
        CAST(NULL AS integer) AS ship_customer_sk,
        CAST(NULL AS integer) AS warehouse_sk,
        CAST(NULL AS integer) AS promo_sk,
        CAST(NULL AS decimal(7,2)) AS net_profit,
        CAST(NULL AS decimal(7,2)) AS sales_amount,
        sr.sr_return_amt AS return_amount,
        sr.sr_return_quantity AS quantity
    FROM store_returns sr
    JOIN item i1 ON sr.sr_item_sk = i1.i_item_sk
    JOIN customer c1 ON sr.sr_customer_sk = c1.c_customer_sk
    UNION ALL
    SELECT
        wr.wr_item_sk AS item_sk,
        CAST(NULL AS integer) AS call_center_sk,
        wr.wr_refunded_customer_sk AS bill_customer_sk,
        wr.wr_returning_customer_sk AS ship_customer_sk,
        CAST(NULL AS integer) AS warehouse_sk,
        CAST(NULL AS integer) AS promo_sk,
        CAST(NULL AS decimal(7,2)) AS net_profit,
        CAST(NULL AS decimal(7,2)) AS sales_amount,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_quantity AS quantity
    FROM web_returns wr
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    JOIN customer c2_refund ON wr.wr_refunded_customer_sk = c2_refund.c_customer_sk
    JOIN customer c2_return ON wr.wr_returning_customer_sk = c2_return.c_customer_sk
),
union_data AS (
    SELECT * FROM sales
    UNION DISTINCT
    SELECT * FROM returns
),
inventory_agg AS (
    SELECT
        inv.inv_item_sk AS item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM inventory inv
    JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    GROUP BY inv.inv_item_sk
),
item_words AS (
    SELECT
        i.i_item_sk,
        word,
        COUNT(*) AS word_freq
    FROM item i
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
    GROUP BY i.i_item_sk, word
),
final_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_color,
        SUM(COALESCE(u.net_profit, 0)) AS total_net_profit,
        SUM(COALESCE(u.sales_amount, 0)) AS total_sales_amount,
        SUM(COALESCE(u.return_amount, 0)) AS total_return_amount,
        COUNT(DISTINCT COALESCE(u.bill_customer_sk, u.ship_customer_sk)) AS distinct_customers,
        COALESCE(ia.total_quantity_on_hand, 0) AS total_quantity_on_hand,
        COALESCE(ia.warehouse_count, 0) AS warehouse_count,
        (SELECT AVG(cs2.cs_coupon_amt)
         FROM catalog_sales cs2
         WHERE cs2.cs_promo_sk = p.p_promo_sk) AS avg_coupon_per_promo,
        SUM(iw.word_freq) AS total_word_count,
        p.p_promo_sk
    FROM union_data u
    JOIN item i ON u.item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON u.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w ON u.warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p ON u.promo_sk = p.p_promo_sk
    LEFT JOIN customer c_bill ON u.bill_customer_sk = c_bill.c_customer_sk
    LEFT JOIN customer c_ship ON u.ship_customer_sk = c_ship.c_customer_sk
    LEFT JOIN inventory_agg ia ON i.i_item_sk = ia.item_sk
    LEFT JOIN item_words iw ON i.i_item_sk = iw.i_item_sk
    GROUP BY i.i_item_sk, i.i_product_name, i.i_category, i.i_brand, i.i_color,
             ia.total_quantity_on_hand, ia.warehouse_count, p.p_promo_sk
)
SELECT
    fa.i_item_sk,
    fa.i_product_name,
    fa.i_category,
    fa.i_brand,
    fa.i_color,
    fa.total_net_profit,
    fa.total_sales_amount,
    fa.total_return_amount,
    fa.distinct_customers,
    fa.total_quantity_on_hand,
    fa.warehouse_count,
    fa.avg_coupon_per_promo,
    fa.total_word_count,
    ROW_NUMBER() OVER (PARTITION BY fa.i_category ORDER BY fa.total_net_profit DESC) AS profit_rank_in_category
FROM final_agg fa
ORDER BY profit_rank_in_category, fa.total_net_profit DESC
OFFSET 0
LIMIT 100
