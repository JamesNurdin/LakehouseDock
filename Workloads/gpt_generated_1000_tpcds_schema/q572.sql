WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
    WHERE inv_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY inv_item_sk, inv_warehouse_sk
),
avg_discount AS (
    SELECT AVG(cs_ext_discount_amt) AS avg_disc
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
)
SELECT *
FROM (
    SELECT
        cp.cp_catalog_number,
        i.i_item_id,
        w.w_warehouse_name,
        d1.d_year,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        ai.total_on_hand,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY cs.cs_ext_sales_price DESC) AS rn,
        (SELECT avg_disc FROM avg_discount) AS overall_avg_discount,
        CASE
            WHEN cs.cs_ext_discount_amt > (SELECT avg_disc FROM avg_discount) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS discount_category
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inv_agg ai ON ai.inv_item_sk = i.i_item_sk AND ai.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
        AND ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    WHERE
        d1.d_year = 2001
        AND i.i_brand = 'Brand#45'
        AND p.p_discount_active = 'Y'
        AND w.w_state = 'CA'
        AND hd.hd_buy_potential = '5001-10000'
        AND cp.cp_department = 'Books'
        AND cs.cs_ext_sales_price > 0
        AND ss.ss_ext_sales_price > 0
) t
WHERE t.rn <= 5
ORDER BY t.w_warehouse_name, t.rn
LIMIT 100
