WITH sales_data AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        d_sale.d_year AS sale_year,
        cd.cd_gender,
        cd.cd_education_status,
        c.c_customer_sk,
        p.p_promo_sk,
        p.p_discount_active,
        inv.inv_quantity_on_hand,
        CASE
            WHEN ss.ss_net_profit > 0 THEN 'Profitable'
            WHEN ss.ss_net_profit = 0 THEN 'Break-even'
            ELSE 'Loss'
        END AS profit_category,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_ext_discount_amt AS discount_amount,
        ss.ss_net_profit AS profit_amount,
        COALESCE(wr.wr_return_quantity, 0) AS return_quantity,
        COALESCE(wr.wr_return_amt, 0) AS return_amount
    FROM store_sales ss
    JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sale.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d_sale.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d_sale.d_year = 2002
      AND i.i_category = 'Sports'
      AND c.c_preferred_cust_flag = 'Y'
),
category_agg AS (
    SELECT
        i_category,
        profit_category,
        SUM(sales_amount) AS total_sales,
        SUM(profit_amount) AS total_profit,
        SUM(inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT i_item_sk) AS distinct_items
    FROM sales_data
    GROUP BY i_category, profit_category
    HAVING SUM(sales_amount) > 10000
)
SELECT
    i_category,
    AVG(total_profit) AS avg_profit_per_category,
    SUM(total_sales) AS category_total_sales,
    SUM(total_inventory_qty) AS category_total_inventory,
    COUNT(*) AS profit_category_count
FROM category_agg
GROUP BY i_category
ORDER BY category_total_sales DESC
LIMIT 100
