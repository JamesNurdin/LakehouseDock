WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_promo_sk,
        d.d_year,
        cp.cp_department,
        cp.cp_type,
        hd.hd_income_band_sk,
        p.p_discount_active
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    -- additional dimension joins for completeness (star topology)
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 1905
      AND cp.cp_type = 'monthly'
      AND p.p_discount_active = 'Y'
      AND cs.cs_net_paid > 1000
)
SELECT
    fs.cs_order_number,
    fs.cs_net_paid,
    fs.cs_net_profit,
    fs.d_year,
    fs.cp_department,
    fs.cp_type,
    fs.hd_income_band_sk,
    (
        SELECT SUM(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_date_sk = fs.cs_sold_date_sk
    ) AS total_inventory_on_sold_date,
    ROW_NUMBER() OVER (PARTITION BY fs.cp_department ORDER BY fs.cs_net_paid DESC) AS dept_sales_rank
FROM filtered_sales fs
ORDER BY dept_sales_rank, fs.cs_net_paid DESC
LIMIT 100
