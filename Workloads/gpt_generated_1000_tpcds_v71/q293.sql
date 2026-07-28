WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_category = 'Electronics'
      AND cs.cs_quantity > 1
      AND ib.ib_upper_bound <= 50000
      AND inv.inv_quantity_on_hand >= 500
      AND cd.cd_gender = 'M'
    GROUP BY i.i_item_sk, i.i_product_name, d_sold.d_year, d_sold.d_month_seq
),
ranked AS (
    SELECT
        s.*, 
        RANK() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY s.total_sales DESC) AS sales_rank
    FROM sales_agg s
)
SELECT
    i_item_sk,
    i_product_name,
    d_year,
    d_month_seq,
    total_sales,
    total_quantity,
    avg_inventory,
    sales_rank,
    CASE WHEN sales_rank <= 5 THEN 'Top5' ELSE 'Other' END AS rank_group
FROM ranked
ORDER BY d_year, d_month_seq, sales_rank
LIMIT 100
